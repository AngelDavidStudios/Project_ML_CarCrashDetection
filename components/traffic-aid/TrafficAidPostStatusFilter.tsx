import * as React from 'react';
import { Table } from '@tanstack/react-table';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CheckSquare, Filter, X } from 'lucide-react';
import {
	DropdownMenu,
	DropdownMenuCheckboxItem,
	DropdownMenuContent,
	DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { TrafficAidPost, TrafficAidPostStatusFilterValue } from './types';
import { useTranslations } from 'next-intl';

interface TrafficAidPostStatusFilterProps {
	table: Table<TrafficAidPost>;
}

const statusOptions = [
	{ value: 'active', labelKey: 'statusActive' },
	{ value: 'inactive', labelKey: 'statusInactive' },
	{ value: 'maintenance', labelKey: 'statusMaintenance' },
];

export function TrafficAidPostStatusFilter({
	table,
}: TrafficAidPostStatusFilterProps) {
	const t = useTranslations('TrafficAidTable');
	const statusColumn = table.getColumn('status');
	const statusFilter =
		statusColumn?.getFilterValue() as TrafficAidPostStatusFilterValue;

	const isFiltered = statusFilter && statusFilter.length > 0;

	// Function to toggle a status value in the filter array
	const toggleStatus = (value: string) => {
		if (!statusColumn) return;

		const currentFilter = statusFilter || [];

		if (currentFilter.includes(value)) {
			// If value exists, remove it
			statusColumn.setFilterValue(currentFilter.filter(item => item !== value));
		} else {
			// If value doesn't exist, add it
			statusColumn.setFilterValue([...currentFilter, value]);
		}
	};

	// Function to clear all status filters
	const clearFilter = () => {
		if (statusColumn) {
			statusColumn.setFilterValue([]);
		}
	};

	return (
		<DropdownMenu modal={false}>
			<DropdownMenuTrigger asChild>
				<Button
					variant='outline'
					size='sm'
					className={`h-9 gap-1 border-border bg-muted hover:bg-accent ${
						isFiltered
							? 'border-blue-600 bg-blue-100 dark:bg-blue-900/20 text-blue-800 dark:text-blue-200'
							: 'text-muted-foreground'
					}`}>
					<Filter className='h-3.5 w-3.5' />
					<span>{t('filterStatus')}</span>
					{isFiltered && (
						<Badge
							variant='secondary'
							className='ml-1 rounded-full bg-blue-100 dark:bg-blue-900 px-1 py-0 text-xs text-blue-800 dark:text-blue-200'>
							{statusFilter.length}
						</Badge>
					)}
				</Button>
			</DropdownMenuTrigger>
			<DropdownMenuContent
				align='start'
				className='w-[180px] border-border bg-card text-foreground'>
				{statusOptions.map(option => (
					<DropdownMenuCheckboxItem
						key={option.value}
						className='flex items-center gap-2 hover:bg-muted'
						checked={statusFilter?.includes(option.value)}
						onCheckedChange={() => toggleStatus(option.value)}>
						{statusFilter?.includes(option.value) && (
							<CheckSquare className='h-4 w-4 text-blue-500' />
						)}
						<span>{t(option.labelKey)}</span>
					</DropdownMenuCheckboxItem>
				))}
				{isFiltered && (
					<div className='border-t border-border p-1'>
						<Button
							variant='outline'
							size='sm'
							className='h-7 w-full gap-1 border-border bg-muted text-xs text-muted-foreground hover:bg-accent'
							onClick={clearFilter}>
							<X className='h-3 w-3' />
							{t('clearFilters')}
						</Button>
					</div>
				)}
			</DropdownMenuContent>
		</DropdownMenu>
	);
}
