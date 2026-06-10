'use client';

import React from 'react';
import { Loader2 } from 'lucide-react';

export function TrafficAidPostLoadingState() {
	const rowWidths = [
		// Row 1
		[80, 70, 90, 75, 85, 60],
		// Row 2
		[65, 95, 70, 80, 55, 75],
		// Row 3
		[90, 60, 85, 70, 65, 80],
		// Row 4
		[75, 85, 60, 95, 70, 65],
		// Row 5
		[65, 80, 75, 90, 60, 85],
	];

	return (
		<div className='min-h-[420px] bg-card'>
			<div className='flex items-center justify-center p-8'>
				<div className='flex flex-col items-center'>
					<Loader2 className='mb-2 h-10 w-10 animate-spin text-blue-500' />
					<h3 className='text-lg font-medium text-muted-foreground'>
						Loading aid posts...
					</h3>
				</div>
			</div>

			<div className='px-4 pb-8'>
				<div className='overflow-hidden rounded-md border border-border'>
					<div className='bg-card py-3'>
						<div className='grid grid-cols-6 gap-6 px-6'>
							{Array.from({ length: 6 }).map((_, i) => (
								<div
									key={i}
									className='h-4 animate-pulse rounded-full bg-muted'
								/>
							))}
						</div>
					</div>
					<div className='divide-y divide-gray-800'>
						{rowWidths.map((row, rowIndex) => (
							<div key={rowIndex} className='py-4'>
								<div className='grid grid-cols-6 gap-6 px-6'>
									{row.map((width, i) => (
										<div
											key={i}
											className='h-4 animate-pulse rounded-full bg-muted'
											style={{
												width: `${width}%`,
												animationDelay: `${(rowIndex * 6 + i) * 100}ms`,
											}}
										/>
									))}
								</div>
							</div>
						))}
					</div>
				</div>
			</div>
		</div>
	);
}
