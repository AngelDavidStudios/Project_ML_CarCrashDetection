'use client';

import React from 'react';
import { useRouter } from 'next/navigation';
import {
	Table,
	TableBody,
	TableCell,
	TableHead,
	TableHeader,
	TableRow,
} from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Clock, Eye, Film } from 'lucide-react';
import { formatTimeAgo } from '@/lib/incident-helper';
import { useTranslations } from 'next-intl';

interface Incident {
	id: string;
	detectedAt: string;
	location?: string;
	confidenceScore: number;
	severity?: 'CRITICAL' | 'MAJOR' | 'MINOR';
	incidentType?: string;
	videoUrl?: string;
	thumbnailUrl?: string;
}

interface PendingVerificationTableProps {
	incidents: Incident[];
	isLoading?: boolean;
	onRefresh: () => void;
}

export function PendingVerificationTable({
	incidents,
}: PendingVerificationTableProps) {
	const router = useRouter();
	const t = useTranslations('PendingTable');

	const handleVerify = (incidentId: string) => {
		router.push(`/incident_verification/${incidentId}`);
	};

	const getSeverityBadge = (
		severity: string | null | undefined,
		confidenceScore: number
	) => {
		const effectiveSeverity =
			severity ||
			(confidenceScore > 0.8
				? '>80%'
				: confidenceScore > 0.6
					? '60-80%'
					: '<60%');

		switch (effectiveSeverity) {
			case '>80%':
				return <Badge className='bg-red-600 text-white'>&gt;80%</Badge>;
			case '60-80%':
				return <Badge className='bg-amber-600 text-white'>60-80%</Badge>;
			case '<60%':
				return <Badge className='bg-blue-600 text-white'>&lt;60%</Badge>;
			default:
				return <Badge className='bg-muted text-foreground'>{t('unknown')}</Badge>;
		}
	};

	return (
		<div className='rounded-md border border-border'>
			<div className='relative w-full overflow-auto'>
				<Table className='w-full caption-bottom text-sm'>
					<TableHeader>
						<TableRow className='border-border hover:bg-transparent'>
							<TableHead className='h-10 whitespace-nowrap px-4 text-left font-medium text-muted-foreground'>
								{t('colSeverity')}
							</TableHead>
							<TableHead className='h-10 whitespace-nowrap px-4 text-left font-medium text-muted-foreground'>
								{t('colLocation')}
							</TableHead>
							<TableHead className='h-10 whitespace-nowrap px-4 text-left font-medium text-muted-foreground'>
								{t('colDetected')}
							</TableHead>
							<TableHead className='h-10 whitespace-nowrap px-4 text-left font-medium text-muted-foreground'>
								{t('colConfidence')}
							</TableHead>
							<TableHead className='h-10 whitespace-nowrap px-4 text-right font-medium text-muted-foreground'>
								{t('colActions')}
							</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{incidents.length === 0 ? (
							<TableRow className='border-border'>
								<TableCell
									colSpan={5}
									className='h-24 text-center text-muted-foreground'>
									{t('empty')}
								</TableCell>
							</TableRow>
						) : (
							incidents.map(incident => (
								<TableRow
									key={incident.id}
									className='border-border hover:bg-muted/50'>
									<TableCell className='px-4 py-3'>
										{getSeverityBadge(
											incident.severity,
											incident.confidenceScore
										)}
									</TableCell>
									<TableCell className='px-4 py-3 text-muted-foreground'>
										{incident.location || t('unknownLocation')}
									</TableCell>
									<TableCell className='px-4 py-3 text-muted-foreground'>
										<div className='flex items-center'>
											<Clock className='mr-1 h-3 w-3 text-muted-foreground' />
											{formatTimeAgo(incident.detectedAt)}
										</div>
									</TableCell>
									<TableCell className='px-4 py-3'>
										<div className='flex items-center'>
											<div className='h-2 w-full max-w-24 overflow-hidden rounded-full bg-accent'>
												<div
													className={`h-full ${
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
											<span className='ml-2 text-muted-foreground'>
												{Math.round(incident.confidenceScore * 100)}%
											</span>
										</div>
									</TableCell>
									<TableCell className='px-4 py-3 text-right'>
										<div className='flex items-center justify-end gap-2'>
											{incident.videoUrl && (
												<Button
													variant='outline'
													size='sm'
													className='h-8 gap-1 border-border bg-muted text-muted-foreground hover:bg-accent hover:text-foreground'
													onClick={() =>
														window.open(incident.videoUrl!, '_blank')
													}>
													<Film className='h-3.5 w-3.5' />
													<span className='sr-only sm:not-sr-only sm:whitespace-nowrap'>
														{t('viewVideo')}
													</span>
												</Button>
											)}
											<Button
												variant='outline'
												size='sm'
												className='h-8 gap-1 border-blue-200 dark:border-blue-800 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 hover:bg-blue-200 dark:hover:bg-blue-900/50 hover:text-blue-800 dark:hover:text-blue-200'
												onClick={() => handleVerify(incident.id)}>
												<Eye className='h-3.5 w-3.5' />
												<span className='sr-only sm:not-sr-only sm:whitespace-nowrap'>
													{t('verify')}
												</span>
											</Button>
										</div>
									</TableCell>
								</TableRow>
							))
						)}
					</TableBody>
				</Table>
			</div>
		</div>
	);
}
