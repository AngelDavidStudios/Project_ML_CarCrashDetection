import * as React from 'react';
import { Table } from '@tanstack/react-table';
import { Button } from '@/components/ui/button';
import {
	Select,
	SelectContent,
	SelectItem,
	SelectTrigger,
	SelectValue,
} from '@/components/ui/select';
import {
	ChevronLeft,
	ChevronRight,
	ChevronsLeft,
	ChevronsRight,
} from 'lucide-react';
import { TrafficAidPost } from './types';
import { useTranslations } from 'next-intl';

interface TrafficAidPostPaginationProps {
	table: Table<TrafficAidPost>;
}

export function TrafficAidPostPagination({
	table,
}: TrafficAidPostPaginationProps) {
	const t = useTranslations('TrafficAidTable');
	return (
		<div className='flex items-center justify-between border-t border-border px-4 py-4'>
			<div className='flex items-center gap-2 text-sm text-muted-foreground'>
				<div>{t('rowsPerPage')}</div>
				<Select
					value={`${table.getState().pagination.pageSize}`}
					onValueChange={value => {
						table.setPageSize(Number(value));
					}}>
					<SelectTrigger className='h-8 w-[70px] border-border bg-muted text-foreground'>
						<SelectValue placeholder={table.getState().pagination.pageSize} />
					</SelectTrigger>
					<SelectContent
						side='top'
						className='border-border bg-card text-foreground'>
						{[5, 10, 20, 30, 40, 50].map(pageSize => (
							<SelectItem
								key={pageSize}
								value={`${pageSize}`}
								className='hover:bg-muted'>
								{pageSize}
							</SelectItem>
						))}
					</SelectContent>
				</Select>
			</div>

			<div className='flex items-center space-x-6 lg:space-x-8'>
				<div className='flex w-[100px] items-center justify-center text-sm text-muted-foreground'>
					{t('pageOf', {
						page: table.getState().pagination.pageIndex + 1,
						total: table.getPageCount(),
					})}
				</div>
				<div className='flex items-center space-x-2'>
					<Button
						variant='outline'
						className='hidden h-8 w-8 border-border bg-muted p-0 text-muted-foreground hover:bg-accent hover:text-foreground disabled:opacity-50 lg:flex'
						onClick={() => table.setPageIndex(0)}
						disabled={!table.getCanPreviousPage()}>
						<span className='sr-only'>{t('firstPage')}</span>
						<ChevronsLeft className='h-4 w-4' />
					</Button>
					<Button
						variant='outline'
						className='h-8 w-8 border-border bg-muted p-0 text-muted-foreground hover:bg-accent hover:text-foreground disabled:opacity-50'
						onClick={() => table.previousPage()}
						disabled={!table.getCanPreviousPage()}>
						<span className='sr-only'>{t('previousPage')}</span>
						<ChevronLeft className='h-4 w-4' />
					</Button>
					<Button
						variant='outline'
						className='h-8 w-8 border-border bg-muted p-0 text-muted-foreground hover:bg-accent hover:text-foreground disabled:opacity-50'
						onClick={() => table.nextPage()}
						disabled={!table.getCanNextPage()}>
						<span className='sr-only'>{t('nextPage')}</span>
						<ChevronRight className='h-4 w-4' />
					</Button>
					<Button
						variant='outline'
						className='hidden h-8 w-8 border-border bg-muted p-0 text-muted-foreground hover:bg-accent hover:text-foreground disabled:opacity-50 lg:flex'
						onClick={() => table.setPageIndex(table.getPageCount() - 1)}
						disabled={!table.getCanNextPage()}>
						<span className='sr-only'>{t('lastPage')}</span>
						<ChevronsRight className='h-4 w-4' />
					</Button>
				</div>
			</div>
		</div>
	);
}
