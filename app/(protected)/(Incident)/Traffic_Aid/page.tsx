'use client';

import React from 'react';
import Dashboard from '@/components/dashboard';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { MapPin } from 'lucide-react';
import { TrafficAidPostTable } from '@/components/traffic-aid/TrafficAidPostTable';

export default function TrafficAidPage() {
	return (
		<Dashboard>
			<div className='mx-auto flex max-w-[1800px] flex-1 flex-col gap-6 p-6 pt-0'>
				<div className='flex flex-col justify-between gap-4 border-b border-border py-6 sm:flex-row sm:items-center'>
					<div>
						<h1 className='text-2xl font-bold tracking-tight text-foreground sm:text-3xl'>
							Traffic Aid Posts
						</h1>
						<p className='mt-1 text-sm text-muted-foreground sm:text-base'>
							Manage emergency response locations across the highway network
						</p>
					</div>
				</div>

				<Card className='border-border bg-card text-foreground'>
					<CardHeader className='border-b border-border pb-7'>
						<div className='flex items-center gap-2'>
							<MapPin className='h-5 w-5 text-blue-500' />
							<CardTitle className='text-xl font-semibold text-foreground'>
								Aid Post Management
							</CardTitle>
						</div>
					</CardHeader>
					<CardContent className='p-6'>
						<TrafficAidPostTable />
					</CardContent>
				</Card>
			</div>
		</Dashboard>
	);
}
