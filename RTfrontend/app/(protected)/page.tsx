'use client';

import { useState, useEffect, useRef } from 'react';
import Dashboard from '@/components/dashboard';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
	Card,
	CardContent,
	CardDescription,
	CardHeader,
	CardTitle,
	CardFooter,
} from '@/components/ui/card';
import { useToast } from '@/hooks/use-toast';
import {
	Loader2,
	Search,
	Video,
	Upload,
	X,
	Play,
	MapPin,
} from 'lucide-react';
import { ScrollArea } from '@/components/ui/scroll-area';
import { cn } from '@/lib/utils';
import { ToastAction } from '@/components/ui/toast';
import { useTranslations } from 'next-intl';

type DetectionLog = {
	time: string;
	message: string;
	severity: 'info' | 'warning' | 'error';
};

export default function Page() {
	// Upload state
	const [videoFile, setVideoFile] = useState<File | null>(null);
	const [videoPreview, setVideoPreview] = useState<string | null>(null);
	const [uploadedVideoUrl, setUploadedVideoUrl] = useState<string | null>(null);
	const [uploading, setUploading] = useState(false);
	const [locationName, setLocationName] = useState('');
	const [latitude, setLatitude] = useState('');
	const [longitude, setLongitude] = useState('');

	// Detection state
	const [accidentDetected, setAccidentDetected] = useState(false);
	const [detectionActive, setDetectionActive] = useState(false);
	const [videoLoaded, setVideoLoaded] = useState(false);
	const [backendReady, setBackendReady] = useState(false);
	const [logs, setLogs] = useState<DetectionLog[]>([]);
	const [connectionStatus, setConnectionStatus] = useState<
		'disconnected' | 'connecting' | 'connected'
	>('disconnected');
	const [lastProcessedTimestamp, setLastProcessedTimestamp] =
		useState<number>(0);
	const [processingComplete, setProcessingComplete] = useState(false);

	const wsRef = useRef<WebSocket | null>(null);
	const canvasRef = useRef<HTMLCanvasElement>(null);
	const logsEndRef = useRef<HTMLDivElement>(null);
	const fileInputRef = useRef<HTMLInputElement>(null);
	const { toast } = useToast();
	const t = useTranslations('Detection');

	useEffect(() => {
		if (logsEndRef.current) {
			logsEndRef.current.scrollIntoView({ behavior: 'smooth' });
		}
	}, [logs]);

	useEffect(() => {
		return () => {
			if (wsRef.current) {
				wsRef.current.close();
				wsRef.current = null;
			}
			if (videoPreview) {
				URL.revokeObjectURL(videoPreview);
			}
		};
		// eslint-disable-next-line react-hooks/exhaustive-deps
	}, []);

	useEffect(() => {
		let pingInterval: NodeJS.Timeout | null = null;

		if (wsRef.current && connectionStatus === 'connected') {
			pingInterval = setInterval(() => {
				if (wsRef.current?.readyState === WebSocket.OPEN) {
					try {
						wsRef.current.send(JSON.stringify({ type: 'ping' }));
					} catch (error) {
						console.error('Error sending ping:', error);
					}
				}
			}, 30000);
		}

		return () => {
			if (pingInterval) clearInterval(pingInterval);
		};
	}, [connectionStatus]);

	const addLog = (
		message: string,
		severity: 'info' | 'warning' | 'error' = 'info'
	) => {
		setLogs(prev => [
			...prev,
			{
				time: new Date().toLocaleTimeString(),
				message,
				severity,
			},
		]);
	};

	const handleVideoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
		const file = e.target.files?.[0] || null;
		if (!file) return;

		if (!file.type.startsWith('video/')) {
			toast({
				title: t('toastInvalidFileTitle'),
				description: t('toastInvalidFileDesc'),
				variant: 'destructive',
			});
			return;
		}

		if (file.size > 100 * 1024 * 1024) {
			toast({
				title: t('toastFileTooLargeTitle'),
				description: t('toastFileTooLargeDesc'),
				variant: 'destructive',
			});
			return;
		}

		// Reset any previous run when a new file is picked
		cleanupExistingConnection();
		setUploadedVideoUrl(null);
		setVideoFile(file);
		if (videoPreview) URL.revokeObjectURL(videoPreview);
		setVideoPreview(URL.createObjectURL(file));
	};

	const handleRemoveVideo = () => {
		cleanupExistingConnection();
		setVideoFile(null);
		setUploadedVideoUrl(null);
		if (videoPreview) {
			URL.revokeObjectURL(videoPreview);
			setVideoPreview(null);
		}
		if (fileInputRef.current) {
			fileInputRef.current.value = '';
		}
	};

	const cleanupExistingConnection = () => {
		if (wsRef.current) {
			wsRef.current.close();
			wsRef.current = null;
		}

		setAccidentDetected(false);
		setLogs([]);
		setDetectionActive(false);
		setVideoLoaded(false);
		setBackendReady(false);
		setLastProcessedTimestamp(0);
		setProcessingComplete(false);

		if (canvasRef.current) {
			const ctx = canvasRef.current.getContext('2d');
			if (ctx) {
				ctx.clearRect(0, 0, canvasRef.current.width, canvasRef.current.height);
			}
		}
	};

	const handleStartDetection = async () => {
		if (!videoFile) {
			toast({
				title: t('toastNoVideoTitle'),
				description: t('toastNoVideoDesc'),
				variant: 'destructive',
			});
			return;
		}

		try {
			cleanupExistingConnection();
			setUploading(true);
			addLog(t('logUploading'));

			// Upload the video to public/uploads so the backend can read it from disk
			let videoUrl = uploadedVideoUrl;
			if (!videoUrl) {
				const formData = new FormData();
				formData.append('video', videoFile);

				const response = await fetch('/api/upload', {
					method: 'POST',
					body: formData,
				});

				if (!response.ok) {
					throw new Error(`Upload failed: ${response.status}`);
				}

				const data = await response.json();
				videoUrl = data.videoUrl;
				setUploadedVideoUrl(videoUrl);
			}

			addLog(t('logVideoUploaded'), 'info');
			connectToDetectionService(videoUrl!);
		} catch (error) {
			console.error('Failed to start detection:', error);
			addLog(t('logError', { message: (error as Error).message }), 'error');
			toast({
				title: t('toastStartFailedTitle'),
				description: (error as Error).message,
				variant: 'destructive',
			});
		} finally {
			setUploading(false);
		}
	};

	const connectToDetectionService = (videoUrl: string) => {
		try {
			setConnectionStatus('connecting');
			addLog(t('logConnecting'));

			const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
			const host =
				process.env.NODE_ENV === 'production'
					? window.location.host
					: 'localhost:8000';

			const ws = new WebSocket(`${protocol}//${host}/ws/detect`);
			wsRef.current = ws;

			ws.onopen = () => {
				setConnectionStatus('connected');
				addLog(t('logConnected'), 'info');
				setDetectionActive(true);

				ws.send(
					JSON.stringify({
						type: 'process_video',
						video_url: videoUrl,
						camera_name: locationName || t('defaultCameraName'),
						latitude: latitude ? parseFloat(latitude) : null,
						longitude: longitude ? parseFloat(longitude) : null,
					})
				);

				addLog(t('logSentVideo'), 'info');
			};

			ws.onmessage = handleWebSocketMessage;
			ws.onclose = handleWebSocketClose;
			ws.onerror = handleWebSocketError;
		} catch (error) {
			console.error('Failed to connect to detection service:', error);
			setConnectionStatus('disconnected');
			addLog(t('logConnectionError', { message: (error as Error).message }), 'error');
		}
	};

	const handleWebSocketMessage = (event: MessageEvent) => {
		try {
			const data = JSON.parse(event.data);
			console.log('Received WebSocket message type:', data.type);

			if (data.type === 'ready') {
				setBackendReady(true);
				addLog('Backend is ready to process video', 'info');
			}

			if (data.type === 'frame') {
				displayFrame(data.frame);
				if (!videoLoaded) {
					setVideoLoaded(true);
				}
			}

			if (data.type === 'processing_complete') {
				setDetectionActive(false);
				setProcessingComplete(true);
				addLog(t('logProcessingComplete'), 'info');

				if (data.accident_found) {
					addLog(t('logAccidentFound'), 'warning');
				} else if (data.accident_found === false) {
					addLog(t('logNoAccident'), 'info');
				}
			}

			if (data.accident_detected) {
				const messageTimestamp = data.timestamp || Date.now();

				if (messageTimestamp > lastProcessedTimestamp) {
					setLastProcessedTimestamp(messageTimestamp);
					setAccidentDetected(true);

					const confidence = data.confidence || 0;
					addLog(
						t('logAccidentDetected', {
							confidence: (confidence * 100).toFixed(1),
						}),
						'error'
					);

					toast({
						title: t('toastAccidentTitle'),
						description: t('toastAccidentDesc'),
						variant: 'destructive',
						duration: 5000,
					});
				} else {
					console.log('Ignoring duplicate accident detection message');
				}
			}

			if (data.type === 'image_saved') {
				console.log('Received accident image URL:', data.image_url);
				addLog(t('logImageSaved', { url: data.image_url }), 'info');

				const incidentData = {
					confidenceScore: data.confidence || 0,
					imageUrl: data.image_url,
					thumbnailUrl: data.image_url,
					latitude: latitude ? parseFloat(latitude) : undefined,
					longitude: longitude ? parseFloat(longitude) : undefined,
					location:
						data.location ||
						locationName ||
						(latitude && longitude
							? `${parseFloat(latitude).toFixed(6)}, ${parseFloat(longitude).toFixed(6)}`
							: undefined),
					incidentType: data.accident_type,
					metadata: {
						frameNumber: data.frame_number,
						detectedAt: new Date().toISOString(),
						accidentType: data.accident_type,
						isLocalFile: true,
					},
				};

				fetch('/api/incidents', {
					method: 'POST',
					headers: {
						'Content-Type': 'application/json',
					},
					body: JSON.stringify(incidentData),
				})
					.then(async response => {
						if (response.ok) {
							const result = await response.json();
							addLog(
								t('logIncidentCreated', { id: result.id || '' }),
								'info'
							);
							toast({
								title: t('toastIncidentTitle'),
								description: t('toastIncidentDesc', { id: result.id }),
								duration: 5000,
								action: (
									<ToastAction
										className='font-semibold'
										asChild
										altText={t('viewIncidentAlt')}>
										<a
											href={`/incident_verification/${result.id}`}
											target='_blank'>
											{t('viewIncident')}
										</a>
									</ToastAction>
								),
							});
						} else {
							const errorText = await response
								.text()
								.catch(() => 'Unknown error');
							addLog(
								t('logIncidentRecordFailed', {
									status: response.status,
									error: errorText,
								}),
								'error'
							);
						}
					})
					.catch(error => {
						console.error('Error creating incident:', error);
						addLog(t('logIncidentError', { message: error.message }), 'error');
					});
			}

			if (data.message) {
				addLog(data.message, data.severity || 'info');
			}

			if (data.type === 'pong') {
				console.log('Received pong from server');
			}
		} catch (error) {
			console.error('Error parsing WebSocket message:', error);
			addLog(t('logParseError', { message: (error as Error).message }), 'warning');
		}
	};

	const displayFrame = (base64Image: string) => {
		if (!canvasRef.current) return;

		const ctx = canvasRef.current.getContext('2d');
		if (!ctx) return;

		const img = new Image();
		img.onload = () => {
			if (canvasRef.current) {
				if (
					canvasRef.current.width !== img.width ||
					canvasRef.current.height !== img.height
				) {
					canvasRef.current.width = img.width;
					canvasRef.current.height = img.height;
				}
				ctx.drawImage(img, 0, 0);
			}
		};
		img.src = `data:image/jpeg;base64,${base64Image}`;
	};

	const handleWebSocketClose = (event: CloseEvent) => {
		setConnectionStatus('disconnected');
		setDetectionActive(false);
		setBackendReady(false);

		const reason =
			event.reason ||
			(event.code === 1006
				? 'Connection closed abnormally'
				: 'Connection closed');

		addLog(t('logDisconnected', { reason }), 'warning');

		// Reconnect only if the video is still being processed
		if (uploadedVideoUrl && !processingComplete) {
			const backoffTime = event.code === 1006 ? 3000 : 1000;
			addLog(
				t('logReconnectIn', { seconds: backoffTime / 1000 }),
				'info'
			);

			setTimeout(() => {
				if (uploadedVideoUrl && !processingComplete) {
					addLog(t('logReconnecting'), 'info');
					connectToDetectionService(uploadedVideoUrl);
				}
			}, backoffTime);
		}
	};

	const handleWebSocketError = () => {
		setConnectionStatus('disconnected');
		setBackendReady(false);
		addLog(t('logWebSocketError'), 'error');
	};

	return (
		<Dashboard>
			<div className='mx-auto flex max-w-[1800px] flex-1 flex-col gap-6 p-6 pt-0'>
				<div className='flex flex-col justify-between gap-4 border-b border-border py-6 sm:flex-row sm:items-center'>
					<div>
						<h1 className='text-2xl font-bold tracking-tight text-foreground sm:text-3xl'>
							{t('title')}
						</h1>
						<p className='mt-1 text-sm text-muted-foreground sm:text-base'>
							{t('subtitle')}
						</p>
					</div>
				</div>

				{!videoFile ? (
					<div className='flex h-[400px] flex-col items-center justify-center gap-6 rounded-xl border border-dashed border-border bg-muted/30 p-8 text-center shadow-xl shadow-black/20'>
						<div className='mb-2 flex h-20 w-20 items-center justify-center rounded-full bg-muted ring-4 ring-border'>
							<Video className='h-10 w-10 text-muted-foreground' />
						</div>
						<div className='max-w-md'>
							<h3 className='mb-2 text-xl font-semibold text-foreground'>
								{t('noVideoTitle')}
							</h3>
							<p className='mb-6 text-muted-foreground'>{t('noVideoDesc')}</p>
							<input
								type='file'
								ref={fileInputRef}
								accept='video/*'
								onChange={handleVideoChange}
								className='hidden'
								id='video-upload'
							/>
							<Button
								size='lg'
								className='gap-2 bg-gradient-to-r from-blue-600 to-blue-700 shadow-lg transition-all duration-200 hover:from-blue-500 hover:to-blue-600'
								onClick={() => fileInputRef.current?.click()}>
								<Upload className='h-4 w-4' />
								{t('uploadVideo')}
							</Button>
							<p className='mt-4 text-xs text-muted-foreground'>
								{t('supportedFormats')}
							</p>
						</div>
					</div>
				) : (
					<div className='grid grid-cols-1 gap-6 lg:grid-cols-2'>
						<Card className='overflow-hidden shadow-xl shadow-black/20'>
							<CardHeader className='flex flex-row items-center justify-between space-y-0 border-b border-border pb-2'>
								<div>
									<CardTitle className='font-bold tracking-tight'>
										{locationName || videoFile.name}
									</CardTitle>
									<CardDescription className='mt-1 flex items-center gap-1 text-muted-foreground'>
										<Video className='h-3 w-3' />
										{videoFile.name}
									</CardDescription>
								</div>
								<div className='flex items-center gap-2'>
									{accidentDetected && (
										<div className='flex items-center gap-2 rounded-full border border-red-200 bg-red-100 px-3 py-1 text-sm font-medium text-red-700 dark:border-red-800 dark:bg-red-950 dark:text-red-300'>
											<div className='h-2 w-2 animate-pulse rounded-full bg-red-500' />
											{t('badgeAccident')}
										</div>
									)}

									{connectionStatus === 'connecting' && (
										<div className='flex items-center gap-2 rounded-full border border-blue-200 bg-blue-100 px-3 py-1 text-sm font-medium text-blue-700 dark:border-blue-800 dark:bg-blue-950 dark:text-blue-300'>
											<Loader2 className='h-3 w-3 animate-spin' />
											{t('badgeConnecting')}
										</div>
									)}
								</div>
							</CardHeader>
							<CardContent className='p-0'>
								<div className='relative overflow-hidden'>
									{detectionActive && (!videoLoaded || !backendReady) ? (
										<div className='absolute inset-0 z-10 flex items-center justify-center bg-background/60 backdrop-blur-sm'>
											<div className='flex flex-col items-center gap-2'>
												<Loader2 className='h-10 w-10 animate-spin text-blue-500' />
												<p className='text-sm text-muted-foreground'>
													{!videoLoaded
														? t('loadingFeed')
														: t('waitingBackend')}
												</p>
											</div>
										</div>
									) : null}

									{/* Show the raw preview until detection starts streaming frames */}
									{!detectionActive && videoPreview ? (
										<video
											src={videoPreview}
											controls
											className='aspect-video w-full bg-black'
										/>
									) : (
										<canvas
											ref={canvasRef}
											className={cn(
												'aspect-video w-full rounded-none bg-black transition-opacity duration-300',
												videoLoaded && backendReady
													? 'opacity-100'
													: 'opacity-0'
											)}
										/>
									)}
								</div>
							</CardContent>
							<CardFooter className='flex flex-col gap-4 border-t border-border px-4 py-4'>
								{/* Optional location metadata for the incident record */}
								<div className='grid w-full grid-cols-1 gap-3 sm:grid-cols-3'>
									<div className='sm:col-span-3'>
										<label className='mb-1 block text-xs font-medium text-muted-foreground'>
											{t('locationLabel')}
										</label>
										<Input
											placeholder={t('locationPlaceholder')}
											value={locationName}
											onChange={e => setLocationName(e.target.value)}
											disabled={detectionActive}
											className='placeholder:text-muted-foreground'
										/>
									</div>
									<div>
										<label className='mb-1 block text-xs font-medium text-muted-foreground'>
											{t('latitudeLabel')}
										</label>
										<Input
											type='number'
											placeholder='-2.170998'
											value={latitude}
											onChange={e => setLatitude(e.target.value)}
											disabled={detectionActive}
											className='placeholder:text-muted-foreground'
										/>
									</div>
									<div>
										<label className='mb-1 block text-xs font-medium text-muted-foreground'>
											{t('longitudeLabel')}
										</label>
										<Input
											type='number'
											placeholder='-79.922359'
											value={longitude}
											onChange={e => setLongitude(e.target.value)}
											disabled={detectionActive}
											className='placeholder:text-muted-foreground'
										/>
									</div>
									<div className='flex items-end'>
										{(latitude || longitude) && (
											<span className='flex items-center gap-1 text-xs text-muted-foreground'>
												<MapPin className='h-3 w-3' />
												{latitude || '—'}, {longitude || '—'}
											</span>
										)}
									</div>
								</div>

								<div className='flex w-full justify-between gap-2'>
									<Button
										variant='outline'
										onClick={handleRemoveVideo}
										disabled={detectionActive || uploading}
										className='gap-2'>
										<X className='h-4 w-4' />
										{t('remove')}
									</Button>
									<Button
										onClick={handleStartDetection}
										disabled={detectionActive || uploading}
										className='gap-2 bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-500 hover:to-blue-600'>
										{uploading || detectionActive ? (
											<Loader2 className='h-4 w-4 animate-spin' />
										) : (
											<Play className='h-4 w-4' />
										)}
										{uploading
											? t('uploading')
											: detectionActive
												? t('detecting')
												: t('startDetection')}
									</Button>
								</div>
							</CardFooter>
						</Card>

						<Card className='flex flex-col shadow-xl shadow-black/20'>
							<CardHeader className='border-b border-border'>
								<CardTitle className='flex items-center justify-between font-bold tracking-tight'>
									<span>{t('logsTitle')}</span>
									{detectionActive ? (
										<span className='flex items-center gap-2 rounded-full border border-green-200 bg-green-100 px-3 py-1 text-sm font-medium text-green-700 dark:border-green-800/50 dark:bg-green-900/30 dark:text-green-400'>
											<span className='h-2 w-2 animate-pulse rounded-full bg-green-500'></span>
											{t('logsActive')}
										</span>
									) : (
										<span className='flex items-center gap-2 rounded-full bg-muted px-3 py-1 text-sm font-medium text-muted-foreground'>
											{t('logsInactive')}
										</span>
									)}
								</CardTitle>
								<CardDescription className='text-muted-foreground'>
									{t('logsDesc')}
								</CardDescription>
							</CardHeader>
							<CardContent className='flex flex-grow flex-col p-0'>
								<ScrollArea className='h-[400px] flex-grow px-6 py-4'>
									<div className='min-h-[350px] space-y-2'>
										{logs.length === 0 ? (
											<div className='flex h-80 flex-col items-center justify-center text-muted-foreground'>
												<div className='mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-muted'>
													<Search className='h-8 w-8 text-muted-foreground' />
												</div>
												<p className='font-medium text-muted-foreground'>
													{t('noLogsTitle')}
												</p>
												<p className='mt-1 text-xs text-muted-foreground'>
													{t('noLogsDesc')}
												</p>
											</div>
										) : (
											<>
												{logs.map((log, index) => (
													<div
														key={index}
														className={cn(
															'flex items-start rounded-lg px-3 py-2 transition-colors',
															log.severity === 'error'
																? 'border-l-4 border-red-500 bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-200'
																: log.severity === 'warning'
																	? 'border-l-4 border-amber-500 bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-200'
																	: 'border-l-4 border-blue-500/50 bg-muted text-muted-foreground'
														)}>
														<span className='mr-3 shrink-0 rounded bg-foreground/10 px-1.5 py-0.5 font-mono text-xs'>
															{log.time}
														</span>
														<span className='font-medium'>{log.message}</span>
													</div>
												))}
												<div ref={logsEndRef} />
											</>
										)}
									</div>
								</ScrollArea>

								<div className='border-t border-border p-4 text-xs text-muted-foreground'>
									{logs.length > 0 ? (
										<div className='flex items-center justify-between'>
											<span>{t('totalEntries', { count: logs.length })}</span>
											<span>
												{t('lastUpdate', {
													time: logs[logs.length - 1].time,
												})}
											</span>
										</div>
									) : (
										<div className='text-center'>{t('logsPlaceholder')}</div>
									)}
								</div>
							</CardContent>
						</Card>
					</div>
				)}
			</div>
		</Dashboard>
	);
}
