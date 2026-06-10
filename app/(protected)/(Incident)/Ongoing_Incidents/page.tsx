'use client';

import React, { useState, useEffect } from 'react';
import {
	Table,
	TableBody,
	TableCell,
	TableHead,
	TableHeader,
	TableRow,
} from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import {
	RefreshCw,
	AlertCircle,
	CheckCircle,
	MapPin,
	Clock,
	Bell,
	CheckCheck,
} from 'lucide-react';
import {
	VerificationStatusBadge,
	SeverityBadge,
} from '@/components/incident-verification/IncidentStatusBadge';
import { formatTimeAgo, getIncidentTypeLabel } from '@/lib/incident-helper';
import Dashboard from '@/components/dashboard';
import type { Incident } from '@/types/incident';
import { useTranslations } from 'next-intl';

export default function OngoingIncidentsPage() {
	const t = useTranslations('Ongoing');
	const [incidents, setIncidents] = useState<Incident[]>([]);
	const [isLoading, setIsLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);

	const fetchVerifiedIncidents = async () => {
		setIsLoading(true);
		setError(null);

		try {
			const response = await fetch('/api/incidents?status=APPROVED');

			if (!response.ok) {
				throw new Error(`Error ${response.status}: ${response.statusText}`);
			}

			const data = await response.json();
			setIncidents(data);
		} catch (err) {
			console.error('Failed to fetch verified incidents:', err);
			setError(t('loadError'));
		} finally {
			setIsLoading(false);
		}
	};

	useEffect(() => {
		fetchVerifiedIncidents();

		const intervalId = setInterval(fetchVerifiedIncidents, 60000);

		return () => clearInterval(intervalId);
	}, []);

	const handleInitiateResponse = async (incidentId: string) => {
		try {
			const response = await fetch(`/api/incidents/${incidentId}`, {
				method: 'PATCH',
				headers: {
					'Content-Type': 'application/json',
				},
				body: JSON.stringify({
					action: 'initiateResponse',
				}),
			});

			if (!response.ok) {
				throw new Error(`Error ${response.status}: ${response.statusText}`);
			}

			fetchVerifiedIncidents();
		} catch (err) {
			console.error('Failed to initiate response:', err);
			alert(t('initiateError'));
		}
	};

	const handleResolveIncident = async (incidentId: string) => {
		try {
			const response = await fetch(`/api/incidents/${incidentId}`, {
				method: 'PATCH',
				headers: {
					'Content-Type': 'application/json',
				},
				body: JSON.stringify({
					action: 'resolve',
				}),
			});

			if (!response.ok) {
				throw new Error(`Error ${response.status}: ${response.statusText}`);
			}

			fetchVerifiedIncidents();
		} catch (err) {
			console.error('Failed to resolve incident:', err);
			alert(t('resolveError'));
		}
	};

	return (
		<Dashboard>
			<div className='container mx-auto py-6'>
				<div className='mb-6 flex flex-col justify-between gap-4 sm:flex-row sm:items-center'>
					<div>
						<h1 className='text-2xl font-bold text-foreground'>{t('title')}</h1>
						<p className='text-muted-foreground'>{t('subtitle')}</p>
					</div>
					<Button
						onClick={fetchVerifiedIncidents}
						variant='outline'
						className='gap-2 self-start border-border bg-muted text-muted-foreground hover:bg-accent hover:text-foreground sm:self-auto'
						disabled={isLoading}>
						<RefreshCw
							className={`h-4 w-4 ${isLoading ? 'animate-spin' : ''}`}
						/>
						{t('refresh')}
					</Button>
				</div>

				{error && (
					<div className='mb-6 rounded-md border border-red-200 dark:border-red-800 bg-red-100 dark:bg-red-900/30 p-4 text-red-700 dark:text-red-300'>
						<div className='flex items-center gap-2'>
							<AlertCircle className='h-5 w-5' />
							<p>{error}</p>
						</div>
					</div>
				)}

				{isLoading ? (
					<div className='grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3'>
						{[...Array(6)].map((_, i) => (
							<div
								key={i}
								className='h-40 animate-pulse rounded-md bg-muted'
							/>
						))}
					</div>
				) : incidents.length === 0 ? (
					<div className='flex flex-col items-center justify-center rounded-lg border border-border bg-muted/50 p-12 text-center'>
						<div className='mb-3 rounded-full bg-green-100 dark:bg-green-900/30 p-3'>
							<CheckCircle className='h-6 w-6 text-green-700 dark:text-green-400' />
						</div>
						<h3 className='mb-1 text-xl font-medium text-foreground'>
							{t('allClear')}
						</h3>
						<p className='max-w-md text-muted-foreground'>{t('empty')}</p>
					</div>
				) : (
					<div className='rounded-md border border-border'>
						<div className='relative w-full overflow-auto'>
							<Table className='w-full caption-bottom text-sm'>
								<TableHeader>
									<TableRow className='border-border hover:bg-transparent'>
										<TableHead className='h-10 whitespace-nowrap px-4 text-left font-medium text-muted-foreground'>
											{t('colStatus')}
										</TableHead>
										<TableHead className='h-10 whitespace-nowrap px-4 text-left font-medium text-muted-foreground'>
											{t('colTypeSeverity')}
										</TableHead>
										<TableHead className='h-10 whitespace-nowrap px-4 text-left font-medium text-muted-foreground'>
											{t('colLocation')}
										</TableHead>
										<TableHead className='h-10 whitespace-nowrap px-4 text-left font-medium text-muted-foreground'>
											{t('colDetected')}
										</TableHead>
										<TableHead className='h-10 whitespace-nowrap px-4 text-left font-medium text-muted-foreground'>
											{t('colVerifiedBy')}
										</TableHead>
										<TableHead className='h-10 whitespace-nowrap px-4 text-right font-medium text-muted-foreground'>
											{t('colActions')}
										</TableHead>
									</TableRow>
								</TableHeader>
								<TableBody>
									{incidents.map(incident => (
										<TableRow
											key={incident.id}
											className='border-border hover:bg-muted/50'>
											<TableCell className='px-4 py-3'>
												{incident.resolvedAt ? (
													<div className='flex items-center'>
														<div className='rounded-full bg-green-500/20 p-1'>
															<CheckCheck className='h-4 w-4 text-green-500' />
														</div>
														<span className='ml-2 text-muted-foreground'>
															{t('statusResolved')}
														</span>
													</div>
												) : incident.responseInitiated ? (
													<div className='flex items-center'>
														<div className='rounded-full bg-blue-500/20 p-1'>
															<Bell className='h-4 w-4 text-blue-500' />
														</div>
														<span className='ml-2 text-muted-foreground'>
															{t('statusResponseInitiated')}
														</span>
													</div>
												) : incident.responseNeeded ? (
													<div className='flex items-center'>
														<div className='rounded-full bg-red-500/20 p-1'>
															<AlertCircle className='h-4 w-4 text-red-500' />
														</div>
														<span className='ml-2 text-muted-foreground'>
															{t('statusResponseNeeded')}
														</span>
													</div>
												) : (
													<VerificationStatusBadge
														status={incident.verificationStatus}
													/>
												)}
											</TableCell>
											<TableCell className='px-4 py-3'>
												<div className='space-y-2'>
													<div className='font-medium text-muted-foreground'>
														{getIncidentTypeLabel(incident.incidentType)}
													</div>
													{incident.severity && (
														<SeverityBadge severity={incident.severity} />
													)}
												</div>
											</TableCell>
											<TableCell className='px-4 py-3 text-muted-foreground'>
												<div className='flex items-center gap-1'>
													<MapPin className='h-3.5 w-3.5 text-muted-foreground' />
													<span>
														{incident.location || t('unknownLocation')}
													</span>
												</div>
											</TableCell>
											<TableCell className='px-4 py-3 text-muted-foreground'>
												<div className='flex items-center gap-1'>
													<Clock className='h-3.5 w-3.5 text-muted-foreground' />
													<span>{formatTimeAgo(incident.detectedAt)}</span>
												</div>
											</TableCell>
											<TableCell className='px-4 py-3'>
												{incident.verifiedByUser ? (
													<div className='flex items-center'>
														{incident.verifiedByUser.image && (
															<img
																src={incident.verifiedByUser.image}
																alt={incident.verifiedByUser.name}
																className='mr-2 h-6 w-6 rounded-full'
															/>
														)}
														<span className='text-muted-foreground'>
															{incident.verifiedByUser.name}
														</span>
													</div>
												) : (
													<span className='text-muted-foreground'>
														{t('unknown')}
													</span>
												)}
											</TableCell>
											<TableCell className='px-4 py-3 text-right'>
												<div className='flex items-center justify-end gap-2'>
													{!incident.resolvedAt &&
														!incident.responseInitiated &&
														incident.responseNeeded && (
															<Button
																variant='outline'
																size='sm'
																className='h-8 gap-1 border-blue-200 dark:border-blue-800 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 hover:bg-blue-200 dark:hover:bg-blue-900/50 hover:text-blue-800 dark:hover:text-blue-200'
																onClick={() =>
																	handleInitiateResponse(incident.id)
																}>
																<Bell className='h-3.5 w-3.5' />
																<span className='sr-only sm:not-sr-only sm:whitespace-nowrap'>
																	{t('initiateResponse')}
																</span>
															</Button>
														)}

													{!incident.resolvedAt && (
														<Button
															variant='outline'
															size='sm'
															className='h-8 gap-1 border-green-200 dark:border-green-800 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300 hover:bg-green-200 dark:hover:bg-green-900/50 hover:text-green-800 dark:hover:text-green-200'
															onClick={() =>
																handleResolveIncident(incident.id)
															}>
															<CheckCheck className='h-3.5 w-3.5' />
															<span className='sr-only sm:not-sr-only sm:whitespace-nowrap'>
																{t('markResolved')}
															</span>
														</Button>
													)}
												</div>
											</TableCell>
										</TableRow>
									))}
								</TableBody>
							</Table>
						</div>
					</div>
				)}
			</div>
		</Dashboard>
	);
}
