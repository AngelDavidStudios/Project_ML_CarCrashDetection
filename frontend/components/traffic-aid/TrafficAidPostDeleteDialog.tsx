import * as React from 'react';
import {
	AlertDialog,
	AlertDialogAction,
	AlertDialogCancel,
	AlertDialogContent,
	AlertDialogDescription,
	AlertDialogFooter,
	AlertDialogHeader,
	AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { TrafficAidPost } from './types';
import { Loader2 } from 'lucide-react';
import { useTranslations } from 'next-intl';

interface TrafficAidPostDeleteDialogProps {
	open: boolean;
	onOpenChange: (open: boolean) => void;
	postsToDelete: TrafficAidPost[];
	onDelete: () => Promise<void>;
	loading: boolean;
}

export function TrafficAidPostDeleteDialog({
	open,
	onOpenChange,
	postsToDelete,
	onDelete,
	loading,
}: TrafficAidPostDeleteDialogProps) {
	const t = useTranslations('TrafficAidTable');
	const postCount = postsToDelete.length;

	return (
		<AlertDialog open={open} onOpenChange={onOpenChange}>
			<AlertDialogContent className='border-border bg-card text-foreground'>
				<AlertDialogHeader>
					<AlertDialogTitle className='text-xl font-semibold text-foreground'>
						{t('deleteTitle', { count: postCount })}
					</AlertDialogTitle>
					<AlertDialogDescription className='text-muted-foreground'>
						{postCount > 1
							? t.rich('deleteDescMany', {
									count: postCount,
									b: chunks => <strong>{chunks}</strong>,
								})
							: t.rich('deleteDescOne', {
									name: postsToDelete[0]?.name ?? '',
									b: chunks => <strong>{chunks}</strong>,
								})}
					</AlertDialogDescription>
				</AlertDialogHeader>
				{postCount > 1 && (
					<div className='my-4 max-h-[200px] overflow-auto rounded border border-border bg-muted/50 p-3'>
						<ul className='list-inside list-disc space-y-1'>
							{postsToDelete.map(post => (
								<li key={post.id} className='text-sm text-muted-foreground'>
									{post.name}{' '}
									<span className='text-muted-foreground'>({post.address})</span>
								</li>
							))}
						</ul>
					</div>
				)}
				<AlertDialogFooter>
					<AlertDialogCancel
						disabled={loading}
						className='border-border bg-muted text-muted-foreground hover:bg-accent hover:text-foreground'>
						{t('cancel')}
					</AlertDialogCancel>
					<AlertDialogAction
						disabled={loading}
						onClick={(e: React.MouseEvent<HTMLButtonElement>) => {
							e.preventDefault();
							onDelete();
						}}
						className='bg-red-600 text-white hover:bg-red-700'>
						{loading ? (
							<>
								<Loader2 className='mr-2 h-4 w-4 animate-spin' />
								{t('deleting')}
							</>
						) : (
							t('delete')
						)}
					</AlertDialogAction>
				</AlertDialogFooter>
			</AlertDialogContent>
		</AlertDialog>
	);
}
