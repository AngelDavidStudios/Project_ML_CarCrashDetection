import React from 'react';
import { Button } from '@/components/ui/button';
import { MapPin, PlusCircle } from 'lucide-react';
import { useTranslations } from 'next-intl';

interface TrafficAidPostEmptyStateProps {
	openAddDialog: () => void;
	columns: number;
}

export function TrafficAidPostEmptyState({
	openAddDialog,
}: TrafficAidPostEmptyStateProps) {
	const t = useTranslations('TrafficAidTable');
	return (
		<div className='flex h-[220px] flex-col items-center justify-center bg-muted/30 p-8 text-center'>
			<div className='mb-4 flex h-20 w-20 items-center justify-center rounded-full bg-muted/50 ring-4 ring-border'>
				<MapPin className='h-10 w-10 text-muted-foreground' />
			</div>
			<h3 className='mb-2 text-xl font-semibold text-muted-foreground'>
				{t('emptyTitle')}
			</h3>
			<p className='mb-6 max-w-[340px] text-muted-foreground'>{t('emptyDesc')}</p>
			<Button
				onClick={openAddDialog}
				className='gap-2 bg-blue-600 hover:bg-blue-700'>
				<PlusCircle className='h-4 w-4' />
				{t('addTitle')}
			</Button>
		</div>
	);
}
