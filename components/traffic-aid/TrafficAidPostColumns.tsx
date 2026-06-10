import * as React from 'react';
import { ColumnDef } from '@tanstack/react-table';
import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import { Badge } from '@/components/ui/badge';
import {
	DropdownMenu,
	DropdownMenuContent,
	DropdownMenuItem,
	DropdownMenuLabel,
	DropdownMenuSeparator,
	DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { ArrowUpDown, Phone, MoreHorizontal, Map } from 'lucide-react';
import { TrafficAidPost } from './types';
import { TrafficAidPostViewDetails } from './TrafficAidPostViewDetails';
import { EditTrafficAidPostDialog } from './EditTrafficAidPostDialog';
import { useTranslations } from 'next-intl';

// Row actions extracted into a real component so hooks (useState) don't run
// inside the column `cell` render function (react-hooks/rules-of-hooks).
function ActionsCell({
	post,
	onEditPost,
}: {
	post: TrafficAidPost;
	onEditPost: React.ComponentProps<typeof EditTrafficAidPostDialog>['onEditPost'];
}) {
	const [viewDetailsOpen, setViewDetailsOpen] = React.useState(false);
	const [editDialogOpen, setEditDialogOpen] = React.useState(false);
	const t = useTranslations('TrafficAidTable');

	return (
		<>
			<DropdownMenu modal={false}>
				<DropdownMenuTrigger asChild>
					<Button
						variant='ghost'
						className='h-8 w-8 p-0 data-[state=open]:bg-accent'>
						<span className='sr-only'>{t('openMenu')}</span>
						<MoreHorizontal className='h-4 w-4' />
					</Button>
				</DropdownMenuTrigger>
				<DropdownMenuContent className='w-[160px] border-border bg-card text-foreground'>
					<DropdownMenuLabel>{t('actions')}</DropdownMenuLabel>
					<DropdownMenuSeparator className='bg-muted' />
					<DropdownMenuItem
						className='cursor-pointer hover:bg-accent'
						onClick={() => setViewDetailsOpen(true)}>
						{t('viewDetails')}
					</DropdownMenuItem>
					<DropdownMenuItem
						className='cursor-pointer hover:bg-accent'
						onClick={() => setEditDialogOpen(true)}>
						{t('edit')}
					</DropdownMenuItem>
					<DropdownMenuItem
						className='cursor-pointer hover:bg-accent'
						onClick={() =>
							window.open(
								`https://maps.google.com/?q=${post.latitude},${post.longitude}`,
								'_blank'
							)
						}>
						<Map className='mr-2 h-4 w-4' />
						{t('viewOnMap')}
					</DropdownMenuItem>
				</DropdownMenuContent>
			</DropdownMenu>
			<EditTrafficAidPostDialog
				open={editDialogOpen}
				onClose={() => setEditDialogOpen(false)}
				post={post}
				onEditPost={onEditPost}
			/>
			<TrafficAidPostViewDetails
				open={viewDetailsOpen}
				onClose={() => setViewDetailsOpen(false)}
				post={post}
			/>
		</>
	);
}

export const createColumns = (
	t: (key: string) => string
): ColumnDef<TrafficAidPost>[] => {
	const handleEditPost = async (
		id: string,
		data: {
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
		}
	) => {
		try {
			const response = await fetch(`/api/trafficaid/${id}`, {
				method: 'PATCH',
				headers: {
					'Content-Type': 'application/json',
				},
				body: JSON.stringify(data),
			});

			if (!response.ok) {
				const errorData = await response.json();
				throw new Error(errorData.error || t('updateError'));
			}

			// Force reload to display the updated data
			window.location.reload();
		} catch (error) {
			console.error('Error updating traffic aid post:', error);
			alert(
				error instanceof Error
					? error.message
					: t('updateError')
			);
		}
	};

	const formatDate = (dateString: string | Date | null) => {
		if (!dateString) return t('na');

		try {
			const date = new Date(dateString);
			if (isNaN(date.getTime())) {
				return t('invalidDate');
			}
			return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
		} catch {
			return t('invalidDate');
		}
	};

	return [
		{
			id: 'select',
			header: ({ table }) => (
				<Checkbox
					checked={
						table.getIsAllPageRowsSelected() ||
						(table.getIsSomePageRowsSelected() && 'indeterminate')
					}
					onCheckedChange={value => table.toggleAllPageRowsSelected(!!value)}
					aria-label={t('selectAll')}
					className='border-border data-[state=checked]:bg-blue-600 data-[state=checked]:text-white'
				/>
			),
			cell: ({ row }) => (
				<Checkbox
					checked={row.getIsSelected()}
					onCheckedChange={value => row.toggleSelected(!!value)}
					aria-label={t('selectRow')}
					className='border-border data-[state=checked]:bg-blue-600 data-[state=checked]:text-white'
				/>
			),
			enableSorting: false,
			enableHiding: false,
		},
		{
			accessorKey: 'name',
			header: ({ column }) => (
				<div
					className='flex cursor-pointer items-center space-x-1'
					onClick={() => column.toggleSorting(column.getIsSorted() === 'asc')}>
					<span>{t('colName')}</span>
					<ArrowUpDown className='h-4 w-4 text-muted-foreground' />
				</div>
			),
			cell: ({ row }) => (
				<div className='font-medium'>{row.getValue('name')}</div>
			),
		},
		{
			accessorKey: 'address',
			header: ({ column }) => (
				<div
					className='flex cursor-pointer items-center space-x-1'
					onClick={() => column.toggleSorting(column.getIsSorted() === 'asc')}>
					<span>{t('colAddress')}</span>
					<ArrowUpDown className='h-4 w-4 text-muted-foreground' />
				</div>
			),
			cell: ({ row }) => (
				<div className='max-w-[250px] truncate' title={row.getValue('address')}>
					{row.getValue('address')}
				</div>
			),
		},
		{
			accessorKey: 'contactNumber',
			header: ({ column }) => (
				<div
					className='flex cursor-pointer items-center space-x-1'
					onClick={() => column.toggleSorting(column.getIsSorted() === 'asc')}>
					<span>{t('colContact')}</span>
					<ArrowUpDown className='h-4 w-4 text-muted-foreground' />
				</div>
			),
			cell: ({ row }) => (
				<div className='flex items-center'>
					<Phone className='mr-2 h-3.5 w-3.5 text-muted-foreground' />
					<span>{row.getValue('contactNumber')}</span>
				</div>
			),
		},
		{
			accessorKey: 'services',
			header: t('colServices'),
			cell: ({ row }) => {
				const post = row.original;
				return (
					<div className='flex flex-wrap gap-1'>
						{post.hasPoliceService && (
							<Badge className='bg-blue-600'>{t('police')}</Badge>
						)}
						{post.hasAmbulance && (
							<Badge className='bg-green-600'>{t('ambulance')}</Badge>
						)}
						{post.hasFireService && <Badge className='bg-red-600'>{t('fire')}</Badge>}
						{!post.hasPoliceService &&
							!post.hasAmbulance &&
							!post.hasFireService && (
								<span className='text-sm text-muted-foreground'>{t('none')}</span>
							)}
					</div>
				);
			},
		},
		{
			accessorKey: 'status',
			header: ({ column }) => (
				<div
					className='flex cursor-pointer items-center space-x-1'
					onClick={() => column.toggleSorting(column.getIsSorted() === 'asc')}>
					<span>{t('colStatus')}</span>
					<ArrowUpDown className='h-4 w-4 text-muted-foreground' />
				</div>
			),
			cell: ({ row }) => {
				const status = row.getValue<string>('status');
				return (
					<Badge
						variant={
							status === 'active'
								? 'default'
								: status === 'inactive'
									? 'secondary'
									: 'destructive'
						}
						className='capitalize'>
						{status}
					</Badge>
				);
			},
			filterFn: (row, id, value) => {
				return value.includes(row.getValue(id));
			},
		},
		{
			accessorKey: 'createdAt',
			header: ({ column }) => (
				<div
					className='flex cursor-pointer items-center space-x-1'
					onClick={() => column.toggleSorting(column.getIsSorted() === 'asc')}>
					<span>{t('colCreatedAt')}</span>
					<ArrowUpDown className='h-4 w-4 text-muted-foreground' />
				</div>
			),
			cell: ({ row }) => {
				const rawDate = row.getValue('createdAt');
				return (
					<div className='text-sm text-muted-foreground'>
						{formatDate(rawDate as string)}
					</div>
				);
			},
		},
		{
			id: 'actions',
			cell: ({ row }) => (
				<ActionsCell post={row.original} onEditPost={handleEditPost} />
			),
		},
	];
};
