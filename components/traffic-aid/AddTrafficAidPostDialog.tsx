'use client';

import * as React from 'react';
import {
	Dialog,
	DialogContent,
	DialogFooter,
	DialogHeader,
	DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import {
	Select,
	SelectContent,
	SelectItem,
	SelectTrigger,
	SelectValue,
} from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';
import { Label } from '@/components/ui/label';
import dynamic from 'next/dynamic';
import { useTranslations } from 'next-intl';

const MapComponent = dynamic(() => import('@/components/MapComponent'), {
	ssr: false,
});

type AddTrafficAidPostDialogProps = {
	open: boolean;
	onClose: () => void;
	onAddPost: (post: {
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
	}) => void;
};

export function AddTrafficAidPostDialog({
	open,
	onClose,
	onAddPost,
}: AddTrafficAidPostDialogProps) {
	const t = useTranslations('TrafficAidForm');
	const [name, setName] = React.useState('');
	const [address, setAddress] = React.useState('');
	const [status, setStatus] = React.useState('active');
	const [location, setLocation] = React.useState<{
		latitude: number;
		longitude: number;
	} | null>(null);
	const [contactNumber, setContactNumber] = React.useState('');
	const [hasPoliceService, setHasPoliceService] = React.useState(false);
	const [hasAmbulance, setHasAmbulance] = React.useState(false);
	const [hasFireService, setHasFireService] = React.useState(false);
	const [operatingHours, setOperatingHours] = React.useState('24/7');
	const [additionalInfo, setAdditionalInfo] = React.useState('');

	// Reset form when dialog closes
	React.useEffect(() => {
		if (!open) {
			// Small delay to avoid visual glitches during closing animation
			const timer = setTimeout(() => {
				setName('');
				setAddress('');
				setStatus('active');
				setLocation(null);
				setContactNumber('');
				setHasPoliceService(false);
				setHasAmbulance(false);
				setHasFireService(false);
				setOperatingHours('24/7');
				setAdditionalInfo('');
			}, 300);
			return () => clearTimeout(timer);
		}
	}, [open]);

	const handleMapClick = (lat: number, lng: number) => {
		setLocation({ latitude: lat, longitude: lng });
	};

	const handleSubmit = () => {
		if (!name || !address || !location || !contactNumber) {
			alert(t('requiredFieldsAlert'));
			return;
		}

		onAddPost({
			name,
			address,
			latitude: location.latitude,
			longitude: location.longitude,
			contactNumber,
			hasPoliceService,
			hasAmbulance,
			hasFireService,
			operatingHours,
			status,
			additionalInfo,
		});
		onClose();
	};

	return (
		<Dialog open={open} onOpenChange={onClose}>
			<DialogContent className='h-[90vh] max-h-[90vh] w-[90vw] max-w-[90vw] overflow-auto bg-card p-0 text-foreground'>
				<div className='flex h-full flex-col'>
					<DialogHeader className='border-b border-border p-6'>
						<DialogTitle className='text-xl font-semibold text-foreground'>
							{t('addTitle')}
						</DialogTitle>
					</DialogHeader>

					<div className='flex h-full flex-1 overflow-hidden'>
						{/* Left Side: Form */}
						<div className='flex w-1/3 flex-col space-y-6 border-r border-border p-6'>
							{/* Post Name */}
							<div>
								<label className='mb-2 block text-sm font-medium text-muted-foreground'>
									{t('nameLabel')}*
								</label>
								<Input
									placeholder={t('namePlaceholder')}
									value={name}
									onChange={e => setName(e.target.value)}
									className='border-border bg-muted text-foreground placeholder:text-muted-foreground focus:border-blue-500 focus:ring-blue-500'
								/>
							</div>

							{/* Post Address */}
							<div>
								<label className='mb-2 block text-sm font-medium text-muted-foreground'>
									{t('addressLabel')}*
								</label>
								<Textarea
									placeholder={t('addressPlaceholder')}
									value={address}
									onChange={e => setAddress(e.target.value)}
									className='border-border bg-muted text-foreground placeholder:text-muted-foreground focus:border-blue-500 focus:ring-blue-500'
									rows={3}
								/>
							</div>

							{/* Contact Number */}
							<div>
								<label className='mb-2 block text-sm font-medium text-muted-foreground'>
									{t('contactLabel')}*
								</label>
								<Input
									placeholder={t('contactPlaceholder')}
									value={contactNumber}
									onChange={e => setContactNumber(e.target.value)}
									className='border-border bg-muted text-foreground placeholder:text-muted-foreground focus:border-blue-500 focus:ring-blue-500'
								/>
							</div>

							{/* Available Services */}
							<div>
								<label className='mb-3 block text-sm font-medium text-muted-foreground'>
									{t('servicesLabel')}
								</label>
								<div className='space-y-3'>
									<div className='flex items-center space-x-2'>
										<Checkbox
											id='police'
											checked={hasPoliceService}
											onCheckedChange={checked =>
												setHasPoliceService(checked === true)
											}
											className='border-border data-[state=checked]:bg-blue-600 data-[state=checked]:text-white'
										/>
										<Label htmlFor='police' className='text-muted-foreground'>
											{t('police')}
										</Label>
									</div>
									<div className='flex items-center space-x-2'>
										<Checkbox
											id='ambulance'
											checked={hasAmbulance}
											onCheckedChange={checked =>
												setHasAmbulance(checked === true)
											}
											className='border-border data-[state=checked]:bg-blue-600 data-[state=checked]:text-white'
										/>
										<Label htmlFor='ambulance' className='text-muted-foreground'>
											{t('ambulance')}
										</Label>
									</div>
									<div className='flex items-center space-x-2'>
										<Checkbox
											id='fire'
											checked={hasFireService}
											onCheckedChange={checked =>
												setHasFireService(checked === true)
											}
											className='border-border data-[state=checked]:bg-blue-600 data-[state=checked]:text-white'
										/>
										<Label htmlFor='fire' className='text-muted-foreground'>
											{t('fire')}
										</Label>
									</div>
								</div>
							</div>

							{/* Operating Hours */}
							<div>
								<label className='mb-2 block text-sm font-medium text-muted-foreground'>
									{t('hoursLabel')}
								</label>
								<Input
									placeholder={t('hoursPlaceholder')}
									value={operatingHours}
									onChange={e => setOperatingHours(e.target.value)}
									className='border-border bg-muted text-foreground placeholder:text-muted-foreground focus:border-blue-500 focus:ring-blue-500'
								/>
							</div>

							{/* Additional Info */}
							<div>
								<label className='mb-2 block text-sm font-medium text-muted-foreground'>
									{t('additionalLabel')}
								</label>
								<Textarea
									placeholder={t('additionalPlaceholder')}
									value={additionalInfo}
									onChange={e => setAdditionalInfo(e.target.value)}
									className='border-border bg-muted text-foreground placeholder:text-muted-foreground focus:border-blue-500 focus:ring-blue-500'
									rows={3}
								/>
							</div>

							{/* Post Status */}
							<div>
								<label className='mb-2 block text-sm font-medium text-muted-foreground'>
									{t('statusLabel')}
								</label>
								<Select value={status} onValueChange={setStatus}>
									<SelectTrigger className='border-border bg-muted text-foreground focus:border-blue-500 focus:ring-blue-500'>
										<SelectValue placeholder={t('selectStatus')} />
									</SelectTrigger>
									<SelectContent className='border-border bg-muted text-foreground'>
										<SelectItem value='active' className='hover:bg-accent'>
											{t('statusActive')}
										</SelectItem>
										<SelectItem value='inactive' className='hover:bg-accent'>
											{t('statusInactive')}
										</SelectItem>
										<SelectItem
											value='maintenance'
											className='hover:bg-accent'>
											{t('statusMaintenance')}
										</SelectItem>
									</SelectContent>
								</Select>
							</div>

							{/* Location Display */}
							{location && (
								<div className='rounded-md border border-border bg-muted p-4'>
									<h3 className='mb-2 text-sm font-medium text-muted-foreground'>
										{t('selectedLocation')}
									</h3>
									<div className='grid grid-cols-2 gap-2'>
										<div>
											<p className='text-xs text-muted-foreground'>
												{t('latitude')}
											</p>
											<p className='text-sm text-foreground'>
												{location.latitude.toFixed(6)}
											</p>
										</div>
										<div>
											<p className='text-xs text-muted-foreground'>
												{t('longitude')}
											</p>
											<p className='text-sm text-foreground'>
												{location.longitude.toFixed(6)}
											</p>
										</div>
									</div>
								</div>
							)}

							{/* Spacer to push buttons to bottom */}
							<div className='flex-grow'></div>

							{/* Buttons */}
							<DialogFooter className='border-t border-border pt-4'>
								<Button
									variant='outline'
									onClick={onClose}
									className='border-border text-muted-foreground hover:bg-muted hover:text-foreground'>
									{t('cancel')}
								</Button>
								<Button
									onClick={handleSubmit}
									className='bg-blue-600 text-white hover:bg-blue-700'>
									{t('addSubmit')}
								</Button>
							</DialogFooter>
						</div>

						{/* Right Side: Map */}
						<div className='flex w-2/3 flex-col'>
							<div className='p-6 pb-3'>
								<label className='mb-2 block text-sm font-medium text-muted-foreground'>
									{t('mapLabel')}*
								</label>
								<p className='mb-2 text-sm text-muted-foreground'>
									{t('mapHint')}
								</p>
							</div>
							<div className='relative flex-1 px-6 pb-6'>
								<div className='absolute inset-0 mx-6 mb-6 overflow-hidden rounded-xl border border-border'>
									<MapComponent
										onLocationSelect={latlng =>
											handleMapClick(latlng.lat, latlng.lng)
										}
										marker={
											location
												? {
														latitude: location.latitude,
														longitude: location.longitude,
													}
												: null
										}
									/>
								</div>
							</div>
						</div>
					</div>
				</div>
			</DialogContent>
		</Dialog>
	);
}
