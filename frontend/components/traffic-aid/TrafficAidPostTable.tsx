'use client';

import * as React from 'react';
import {
	ColumnFiltersState,
	SortingState,
	VisibilityState,
	flexRender,
	getCoreRowModel,
	getFilteredRowModel,
	getPaginationRowModel,
	getSortedRowModel,
	useReactTable,
} from '@tanstack/react-table';
import {
	Table,
	TableBody,
	TableCell,
	TableHead,
	TableHeader,
	TableRow,
} from '@/components/ui/table';
import { useToast } from '@/hooks/use-toast';
import { cn } from '@/lib/utils';
import { useTranslations } from 'next-intl';
import { TrafficAidPost } from './types';
import { createColumns } from './TrafficAidPostColumns';
import { TrafficAidPostTableHeader } from './TrafficAidPostTableHeader';
import { TrafficAidPostLoadingState } from './TrafficAidPostLoadingState';
import { TrafficAidPostEmptyState } from './TrafficAidPostEmptyState';
import { TrafficAidPostPagination } from './TrafficAidPostPagination';
import { TrafficAidPostDeleteDialog } from './TrafficAidPostDeleteDialog';
import { AddTrafficAidPostDialog } from './AddTrafficAidPostDialog';

export function TrafficAidPostTable() {
	const { toast } = useToast();
	const t = useTranslations('TrafficAidTable');
	const [data, setData] = React.useState<TrafficAidPost[]>([]);
	const [loading, setLoading] = React.useState<boolean>(true);
	const [isDialogOpen, setIsDialogOpen] = React.useState(false);
	const [isAddDialogOpen, setIsAddDialogOpen] = React.useState(false);
	const [postsToDelete, setPostsToDelete] = React.useState<TrafficAidPost[]>(
		[]
	);
	const [rowSelection, setRowSelection] = React.useState({});
	const [sorting, setSorting] = React.useState<SortingState>([]);
	const [columnFilters, setColumnFilters] = React.useState<ColumnFiltersState>(
		[]
	);
	const [columnVisibility, setColumnVisibility] =
		React.useState<VisibilityState>({});
	const [refreshKey, setRefreshKey] = React.useState(0);

	const columns = React.useMemo(() => createColumns(t), [t]);

	React.useEffect(() => {
		const fetchData = async () => {
			try {
				setLoading(true);
				const response = await fetch('/api/trafficaid');

				if (!response.ok) {
					throw new Error(`API error: ${response.status}`);
				}

				const result = await response.json();
				setData(result);
			} catch (error) {
				console.error('Error fetching traffic aid post data:', error);
				toast({
					title: t('toastFetchErrorTitle'),
					description: (error as Error).message || t('toastFetchErrorDesc'),
					variant: 'destructive',
				});
			} finally {
				setLoading(false);
			}
		};

		fetchData();
	}, [toast, refreshKey]);

	const table = useReactTable({
		data,
		columns,
		onSortingChange: setSorting,
		onColumnFiltersChange: setColumnFilters,
		getCoreRowModel: getCoreRowModel(),
		getPaginationRowModel: getPaginationRowModel(),
		getSortedRowModel: getSortedRowModel(),
		getFilteredRowModel: getFilteredRowModel(),
		onColumnVisibilityChange: setColumnVisibility,
		onRowSelectionChange: setRowSelection,
		state: {
			sorting,
			columnFilters,
			columnVisibility,
			rowSelection,
		},
	});

	const handleAddPost = async (newPost: {
		name: string;
		address: string;
		latitude: number;
		longitude: number;
		contactNumber: string;
		hasPoliceService: boolean;
		hasAmbulance: boolean;
		hasFireService: boolean;
		operatingHours: string;
		status: string;
		additionalInfo?: string;
	}) => {
		try {
			const response = await fetch('/api/trafficaid', {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json',
				},
				body: JSON.stringify(newPost),
			});

			if (!response.ok) {
				throw new Error(`API error: ${response.status}`);
			}

			const createdPost = await response.json();

			setData(prevData => [...prevData, createdPost]);
			toast({
				title: t('toastAddedTitle'),
				description: t('toastAddedDesc', { name: newPost.name }),
			});
		} catch (error) {
			console.error('Error adding traffic aid post:', error);
			toast({
				title: t('toastAddErrorTitle'),
				description: (error as Error).message || t('toastAddErrorDesc'),
				variant: 'destructive',
			});
		}
	};

	const handleDeletePost = async () => {
		if (postsToDelete.length === 0) return;

		try {
			setLoading(true);
			for (const post of postsToDelete) {
				const response = await fetch(`/api/trafficaid/${post.id}`, {
					method: 'DELETE',
				});

				if (!response.ok) {
					throw new Error(
						`API error when deleting ${post.name}: ${response.status}`
					);
				}
			}

			const remainingData = data.filter(
				post => !postsToDelete.some(row => row.id === post.id)
			);
			setData(remainingData);

			toast({
				title: t('toastDeletedTitle'),
				description: t('toastDeletedDesc', { count: postsToDelete.length }),
			});

			setRowSelection({});
		} catch (error) {
			console.error('Error deleting traffic aid post(s):', error);
			toast({
				title: t('toastDeleteErrorTitle'),
				description: (error as Error).message || t('toastDeleteErrorDesc'),
				variant: 'destructive',
			});
		} finally {
			setLoading(false);
			setIsDialogOpen(false);
			setPostsToDelete([]);
		}
	};

	const refreshData = () => {
		setRefreshKey(prev => prev + 1);
	};

	const openDeleteDialog = () => {
		const selectedRows = table
			.getSelectedRowModel()
			.rows.map(row => row.original);

		if (selectedRows.length === 0) {
			toast({
				description: t('toastSelectAtLeastOne'),
			});
			return;
		}

		setPostsToDelete(selectedRows);
		setIsDialogOpen(true);
	};

	return (
		<div className='w-full'>
			<TrafficAidPostTableHeader
				table={table}
				loading={loading}
				refreshData={refreshData}
				openAddDialog={() => setIsAddDialogOpen(true)}
				openDeleteDialog={openDeleteDialog}
			/>

			{/* Table */}
			<div className='overflow-hidden rounded-b-md border border-t-0 border-border'>
				{loading ? (
					<TrafficAidPostLoadingState />
				) : (
					<>
						<div className='relative overflow-x-auto'>
							<Table className='border-collapse'>
								<TableHeader className='bg-card'>
									{table.getHeaderGroups().map(headerGroup => (
										<TableRow
											key={headerGroup.id}
											className='border-border hover:bg-transparent'>
											{headerGroup.headers.map(header => (
												<TableHead
													key={header.id}
													className='h-10 border-b border-border text-muted-foreground'>
													{header.isPlaceholder
														? null
														: flexRender(
																header.column.columnDef.header,
																header.getContext()
															)}
												</TableHead>
											))}
										</TableRow>
									))}
								</TableHeader>
								<TableBody>
									{table.getRowModel().rows?.length ? (
										table.getRowModel().rows.map(row => (
											<TableRow
												key={row.id}
												className={cn(
													'border-border data-[state=selected]:bg-muted',
													row.getIsSelected()
														? 'bg-muted/80'
														: 'hover:bg-muted/50'
												)}
												data-state={
													row.getIsSelected() ? 'selected' : undefined
												}>
												{row.getVisibleCells().map(cell => (
													<TableCell
														key={cell.id}
														className='py-3 first:pl-6 last:pr-6'>
														{flexRender(
															cell.column.columnDef.cell,
															cell.getContext()
														)}
													</TableCell>
												))}
											</TableRow>
										))
									) : (
										<tr>
											<td colSpan={columns.length}>
												<TrafficAidPostEmptyState
													openAddDialog={() => setIsAddDialogOpen(true)}
													columns={columns.length}
												/>
											</td>
										</tr>
									)}
								</TableBody>
							</Table>
						</div>

						<TrafficAidPostPagination table={table} />
					</>
				)}
			</div>

			{/* Dialogs */}
			<AddTrafficAidPostDialog
				open={isAddDialogOpen}
				onClose={() => setIsAddDialogOpen(false)}
				onAddPost={handleAddPost}
			/>

			<TrafficAidPostDeleteDialog
				open={isDialogOpen}
				onOpenChange={setIsDialogOpen}
				postsToDelete={postsToDelete}
				onDelete={handleDeletePost}
				loading={loading}
			/>
		</div>
	);
}
