'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { AccidentImage } from '@/components/incident-verification/AccidentImage';
import { IncidentVerificationForm } from '@/components/incident-verification/IncidentVerificationForm';
import {
	VerificationStatusBadge,
	SeverityBadge,
} from '@/components/incident-verification/IncidentStatusBadge';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import {
	ArrowLeft,
	Calendar,
	MapPin,
	Info,
	Clock,
	AlertCircle,
} from 'lucide-react';
import { formatIncidentDate, formatTimeAgo } from '@/lib/incident-helper';
import Dashboard from '@/components/dashboard';
import type { Incident, IncidentVerificationFormData } from '@/types/incident';
import { useTranslations } from 'next-intl';

interface IncidentVerificationPageProps {
	params: Promise<{ id: string }>;
}

export default function IncidentVerificationDetailPage({
	params,
}: IncidentVerificationPageProps) {
	const router = useRouter();
	const t = useTranslations('Verification');

	const [id, setId] = useState<string | null>(null);

	const [incident, setIncident] = useState<Incident | null>(null);
	const [isLoading, setIsLoading] = useState<boolean>(true);
	const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
	const [error, setError] = useState<string | null>(null);

	useEffect(() => {
		let isMounted = true;

		params
			.then(resolved => {
				if (isMounted) {
					setId(resolved.id);
				}
			})
			.catch(err => {
				console.error('Failed to unwrap params:', err);
			});

		return () => {
			isMounted = false;
		};
	}, [params]);

	useEffect(() => {
		if (!id) return;

		setIsLoading(true);
		setError(null);

		const fetchIncident = async () => {
			try {
				const response = await fetch(`/api/incidents/${id}`);
				if (!response.ok) {
					if (response.status === 404) {
						throw new Error(t('errIncidentNotFound'));
					}
					throw new Error(`Error ${response.status}: ${response.statusText}`);
				}
				const data = await response.json();
				setIncident(data);
			} catch (err) {
				console.error('Failed to fetch incident:', err);
				setError(
					err instanceof Error ? err.message : t('errLoadDetails')
				);
			} finally {
				setIsLoading(false);
			}
		};

		fetchIncident();
	}, [id]);

	const handleVerify = async (verificationData: IncidentVerificationFormData) => {
		if (!id) return;

		setIsSubmitting(true);
		setError(null);

		try {
			const response = await fetch(`/api/incidents/${id}`, {
				method: 'PATCH',
				headers: {
					'Content-Type': 'application/json',
				},
				body: JSON.stringify(verificationData),
			});

			if (!response.ok) {
				throw new Error(`Error ${response.status}: ${response.statusText}`);
			}
			router.push('/Pending_Verification');
			router.refresh();
		} catch (err) {
			console.error('Failed to verify incident:', err);
			setError(
				err instanceof Error ? err.message : t('errSubmit')
			);
			setIsSubmitting(false);
		}
	};

	if (isLoading) {
		return (
			<Dashboard>
				<div className='container mx-auto py-6'>
					<div className='mb-6'>
						<Skeleton className='h-8 w-48 bg-muted' />
						<Skeleton className='mt-2 h-4 w-64 bg-muted' />
					</div>
					<div className='grid grid-cols-1 gap-8 lg:grid-cols-5'>
						<div className='lg:col-span-3'>
							<Skeleton className='aspect-video w-full bg-muted' />
							<div className='mt-4 grid grid-cols-2 gap-4'>
								<Skeleton className='h-24 bg-muted' />
								<Skeleton className='h-24 bg-muted' />
							</div>
						</div>
						<div className='lg:col-span-2'>
							<Skeleton className='h-96 bg-muted' />
						</div>
					</div>
				</div>
			</Dashboard>
		);
	}

	if (error) {
		return (
			<Dashboard>
				<div className='container mx-auto py-6'>
					<Button
						variant='outline'
						className='mb-6 gap-2 border-border bg-muted text-muted-foreground hover:bg-accent'
						onClick={() => router.push('/Pending_Verification')}>
						<ArrowLeft className='h-4 w-4' />
						{t('backToQueue')}
					</Button>
					<div className='rounded-md border border-red-200 dark:border-red-800 bg-red-100 dark:bg-red-900/30 p-6 text-center'>
						<AlertCircle className='mx-auto mb-3 h-10 w-10 text-red-700 dark:text-red-400' />
						<h3 className='text-xl font-semibold text-foreground'>
							{t('errorTitle')}
						</h3>
						<p className='mt-2 text-red-700 dark:text-red-300'>{error}</p>
						<Button
							className='mt-4 bg-red-700 hover:bg-red-800'
							onClick={() => window.location.reload()}>
							{t('tryAgain')}
						</Button>
					</div>
				</div>
			</Dashboard>
		);
	}

	if (!incident) {
		return (
			<Dashboard>
				<div className='container mx-auto py-6'>
					<Button
						variant='outline'
						className='mb-6 gap-2 border-border bg-muted text-muted-foreground hover:bg-accent'
						onClick={() => router.push('/Pending_Verification')}>
						<ArrowLeft className='h-4 w-4' />
						{t('backToQueue')}
					</Button>
					<div className='rounded-md border border-amber-200 dark:border-amber-800 bg-amber-100 dark:bg-amber-900/30 p-6 text-center'>
						<Info className='mx-auto mb-3 h-10 w-10 text-amber-700 dark:text-amber-400' />
						<h3 className='text-xl font-semibold text-foreground'>
							{t('notFoundTitle')}
						</h3>
						<p className='mt-2 text-amber-700 dark:text-amber-300'>
							{t('notFoundDesc')}
						</p>
						<Button
							variant='outline'
							className='mt-4 border-amber-200 dark:border-amber-700 bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-300 hover:bg-amber-200 dark:hover:bg-amber-900/50'
							onClick={() => router.push('/Pending_Verification')}>
							{t('returnToQueue')}
						</Button>
					</div>
				</div>
			</Dashboard>
		);
	}

	return (
		<Dashboard>
			<div className='container mx-auto py-6'>
				<Button
					variant='outline'
					className='mb-6 gap-2 border-border bg-muted text-muted-foreground hover:bg-accent'
					onClick={() => router.push('/Pending_Verification')}>
					<ArrowLeft className='h-4 w-4' />
					Back to Verification Queue
				</Button>

				<div className='mb-6'>
					<div className='flex items-center gap-3'>
						<h1 className='text-2xl font-bold text-foreground'>
							{t('pageTitle')}
						</h1>
						<VerificationStatusBadge status={incident.verificationStatus} />
					</div>
					<p className='text-muted-foreground'>
						{t('pageSubtitle', {
							location: incident.location || t('anUnknownLocation'),
						})}
					</p>
				</div>

				<div className='grid grid-cols-1 gap-8 lg:grid-cols-5'>
					<div className='space-y-6 lg:col-span-3'>
						{/* Video Player */}
						<div className='overflow-hidden rounded-lg border border-border bg-black'>
							<AccidentImage
								imageUrl={incident.imageUrl}
								alt={t('imageAlt', {
									location: incident.location || t('unknownLocation'),
								})}
								className='rounded-md border border-border'
							/>
						</div>

						{/* Incident Details */}
						<div className='rounded-lg border border-border bg-muted p-4'>
							<h3 className='mb-4 text-lg font-medium text-foreground'>
								{t('detailsTitle')}
							</h3>
							<div className='grid grid-cols-1 gap-4 md:grid-cols-2'>
								<div className='space-y-1'>
									<p className='text-sm text-muted-foreground'>
										{t('fieldLocation')}
									</p>
									<div className='flex items-center gap-1'>
										<MapPin className='h-4 w-4 text-muted-foreground' />
										<p className='font-medium text-foreground'>
											{incident.location || t('unknownLocation')}
										</p>
									</div>
								</div>
								<div className='space-y-1'>
									<p className='text-sm text-muted-foreground'>
										{t('fieldDetectedAt')}
									</p>
									<div className='flex items-center gap-1'>
										<Calendar className='h-4 w-4 text-muted-foreground' />
										<p className='font-medium text-foreground'>
											{formatIncidentDate(incident.detectedAt)}
										</p>
									</div>
								</div>
								<div className='space-y-1'>
									<p className='text-sm text-muted-foreground'>
										{t('fieldTimeSince')}
									</p>
									<div className='flex items-center gap-1'>
										<Clock className='h-4 w-4 text-muted-foreground' />
										<p className='font-medium text-foreground'>
											{formatTimeAgo(incident.detectedAt)}
										</p>
									</div>
								</div>
								<div className='space-y-1'>
									<p className='text-sm text-muted-foreground'>
										{t('fieldConfidence')}
									</p>
									<div className='flex items-center gap-2'>
										<div className='h-2 w-full max-w-24 rounded-full bg-accent'>
											<div
												className={`h-full rounded-full ${
													incident.confidenceScore > 0.7
														? 'bg-red-600'
														: incident.confidenceScore > 0.5
															? 'bg-amber-600'
															: 'bg-blue-600'
												}`}
												style={{
													width: `${Math.round(incident.confidenceScore * 100)}%`,
												}}
											/>
										</div>
										<span className='font-medium text-foreground'>
											{Math.round(incident.confidenceScore * 100)}%
										</span>
									</div>
								</div>
								{incident.incidentType && (
									<div className='space-y-1'>
										<p className='text-sm text-muted-foreground'>
											{t('fieldType')}
										</p>
										<p className='font-medium text-foreground'>
											{incident.incidentType}
										</p>
									</div>
								)}
								{incident.severity && (
									<div className='space-y-1'>
										<p className='text-sm text-muted-foreground'>
											{t('fieldSeverity')}
										</p>
										<SeverityBadge severity={incident.severity} />
									</div>
								)}
							</div>
						</div>
					</div>

					{/* Verification Form */}
					<div className='lg:col-span-2'>
						<div className='rounded-lg border border-border bg-muted p-6'>
							<IncidentVerificationForm
								incident={incident}
								onVerify={handleVerify}
								isSubmitting={isSubmitting}
							/>
						</div>
					</div>
				</div>
			</div>
		</Dashboard>
	);
}
