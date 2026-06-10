import * as React from 'react';
import {
	Dialog,
	DialogContent,
	DialogHeader,
	DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Calendar, Clock, MapPin, Phone, ExternalLink } from 'lucide-react';
import { TrafficAidPost } from './types';
import dynamic from 'next/dynamic';

const MapComponent = dynamic(() => import('@/components/MapComponent'), {
	ssr: false,
});

interface TrafficAidPostViewDetailsProps {
	open: boolean;
	onClose: () => void;
	post: TrafficAidPost;
}

export function TrafficAidPostViewDetails({
	open,
	onClose,
	post,
}: TrafficAidPostViewDetailsProps) {
	const formatDate = (dateString: string) => {
		try {
			const date = new Date(dateString);
			return date.toLocaleDateString(undefined, {
				year: 'numeric',
				month: 'long',
				day: 'numeric',
				hour: '2-digit',
				minute: '2-digit',
			});
		} catch {
			return 'Invalid date';
		}
	};

	return (
		<Dialog open={open} onOpenChange={onClose}>
			<DialogContent className='max-w-4xl bg-card p-0 text-foreground'>
				<DialogHeader className='border-b border-border p-6'>
					<DialogTitle className='text-xl font-semibold text-foreground'>
						{post.name}
					</DialogTitle>
					<div className='mt-1 flex flex-wrap items-center gap-2 text-sm text-muted-foreground'>
						<span className='flex items-center gap-1'>
							<Calendar className='h-3.5 w-3.5' />
							Created: {formatDate(post.createdAt)}
						</span>
						<span className='flex items-center gap-1'>
							<Clock className='h-3.5 w-3.5' />
							Last updated: {formatDate(post.updatedAt)}
						</span>
					</div>
				</DialogHeader>

				<Tabs defaultValue='details' className='p-6'>
					<TabsList className='mb-6 grid w-full grid-cols-2 bg-muted'>
						<TabsTrigger
							value='details'
							className='data-[state=active]:bg-accent data-[state=active]:text-foreground'>
							Details
						</TabsTrigger>
						<TabsTrigger
							value='location'
							className='data-[state=active]:bg-accent data-[state=active]:text-foreground'>
							Location
						</TabsTrigger>
					</TabsList>

					<TabsContent value='details' className='mt-0'>
						<div className='space-y-6'>
							{/* Post Status */}
							<div className='flex items-center gap-2'>
								<Badge
									className={` ${
										post.status === 'active'
											? 'bg-green-600 hover:bg-green-700'
											: post.status === 'maintenance'
												? 'bg-amber-600 hover:bg-amber-700'
												: 'bg-muted hover:bg-accent'
									} `}>
									{post.status.toUpperCase()}
								</Badge>
							</div>

							{/* Available Services */}
							<div>
								<h3 className='mb-3 text-sm font-semibold text-muted-foreground'>
									Available Services
								</h3>
								<div className='flex flex-wrap gap-2'>
									{post.hasPoliceService && (
										<Badge className='bg-blue-600 hover:bg-blue-700'>
											Traffic Police
										</Badge>
									)}
									{post.hasAmbulance && (
										<Badge className='bg-green-600 hover:bg-green-700'>
											Ambulance
										</Badge>
									)}
									{post.hasFireService && (
										<Badge className='bg-red-600 hover:bg-red-700'>
											Fire Department
										</Badge>
									)}
									{!post.hasPoliceService &&
										!post.hasAmbulance &&
										!post.hasFireService && (
											<span className='text-muted-foreground'>
												No services available
											</span>
										)}
								</div>
							</div>

							{/* Address */}
							<div>
								<h3 className='mb-2 text-sm font-semibold text-muted-foreground'>
									Address
								</h3>
								<div className='rounded-md border border-border bg-muted p-3 text-muted-foreground'>
									<div className='flex items-start gap-2'>
										<MapPin className='mt-0.5 h-4 w-4 flex-shrink-0 text-muted-foreground' />
										<span>{post.address}</span>
									</div>
								</div>
							</div>

							{/* Contact Information */}
							<div>
								<h3 className='mb-2 text-sm font-semibold text-muted-foreground'>
									Contact Information
								</h3>
								<div className='rounded-md border border-border bg-muted p-3 text-muted-foreground'>
									<div className='flex items-center gap-2'>
										<Phone className='h-4 w-4 text-muted-foreground' />
										<span>{post.contactNumber}</span>
									</div>
								</div>
							</div>

							{/* Operating Hours */}
							<div>
								<h3 className='mb-2 text-sm font-semibold text-muted-foreground'>
									Operating Hours
								</h3>
								<div className='rounded-md border border-border bg-muted p-3 text-muted-foreground'>
									<div className='flex items-center gap-2'>
										<Clock className='h-4 w-4 text-muted-foreground' />
										<span>{post.operatingHours}</span>
									</div>
								</div>
							</div>

							{/* Additional Information */}
							{post.additionalInfo && (
								<div>
									<h3 className='mb-2 text-sm font-semibold text-muted-foreground'>
										Additional Information
									</h3>
									<div className='rounded-md border border-border bg-muted p-3 text-muted-foreground'>
										<p>{post.additionalInfo}</p>
									</div>
								</div>
							)}
						</div>
					</TabsContent>

					<TabsContent value='location' className='mt-0'>
						<div className='space-y-4'>
							<div className='flex items-center justify-between'>
								<div>
									<h3 className='text-sm font-semibold text-muted-foreground'>
										Location Coordinates
									</h3>
									<p className='text-sm text-muted-foreground'>
										Latitude: {post.latitude.toFixed(6)}, Longitude:{' '}
										{post.longitude.toFixed(6)}
									</p>
								</div>
								<Button
									variant='outline'
									size='sm'
									onClick={() =>
										window.open(
											`https://maps.google.com/?q=${post.latitude},${post.longitude}`,
											'_blank'
										)
									}
									className='gap-2 border-border text-muted-foreground hover:bg-muted hover:text-foreground'>
									<ExternalLink className='h-4 w-4' />
									Open in Google Maps
								</Button>
							</div>

							<div className='h-[400px] overflow-hidden rounded-lg border border-border'>
								<MapComponent
									marker={{
										latitude: post.latitude,
										longitude: post.longitude,
									}}
									interactive={false}
								/>
							</div>
						</div>
					</TabsContent>
				</Tabs>
			</DialogContent>
		</Dialog>
	);
}
