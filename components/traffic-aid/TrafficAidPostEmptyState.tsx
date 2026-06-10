import React from 'react';
import { Button } from '@/components/ui/button';
import { MapPin, PlusCircle } from 'lucide-react';

interface TrafficAidPostEmptyStateProps {
	openAddDialog: () => void;
	columns: number;
}

export function TrafficAidPostEmptyState({
	openAddDialog,
}: TrafficAidPostEmptyStateProps) {
	return (
		<div className='flex h-[220px] flex-col items-center justify-center bg-muted/30 p-8 text-center'>
			<div className='mb-4 flex h-20 w-20 items-center justify-center rounded-full bg-muted/50 ring-4 ring-border'>
				<MapPin className='h-10 w-10 text-muted-foreground' />
			</div>
			<h3 className='mb-2 text-xl font-semibold text-muted-foreground'>
				No traffic aid posts found
			</h3>
			<p className='mb-6 max-w-[340px] text-muted-foreground'>
				There are no traffic aid posts registered in the system yet. Add your
				first traffic aid post to get started.
			</p>
			<Button
				onClick={openAddDialog}
				className='gap-2 bg-blue-600 hover:bg-blue-700'>
				<PlusCircle className='h-4 w-4' />
				Add Traffic Aid Post
			</Button>
		</div>
	);
}
