'use client';

import React from 'react';
import {
	Select,
	SelectContent,
	SelectItem,
	SelectTrigger,
	SelectValue,
} from '@/components/ui/select';
import {
	Form,
	FormControl,
	FormDescription,
	FormField,
	FormItem,
	FormLabel,
} from '@/components/ui/form';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Checkbox } from '@/components/ui/checkbox';
import { zodResolver } from '@hookform/resolvers/zod';
import { useForm } from 'react-hook-form';
import * as z from 'zod';
import { CheckCircle2, XCircle, Loader2 } from 'lucide-react';
import {
	IncidentSeverity,
	IncidentType,
	VerificationStatus,
} from '@prisma/client';
import type {
	Incident,
	IncidentVerificationFormData,
} from '@/types/incident';
import { useTranslations } from 'next-intl';

const formSchema = z.object({
	verificationStatus: z.enum(['APPROVED', 'REJECTED']),
	incidentType: z.string().nullable(),
	severity: z.string().nullable(),
	notes: z.string().min(0).max(500).optional(),
	responseNeeded: z.boolean(),
});

type FormValues = z.infer<typeof formSchema>;

interface IncidentVerificationFormProps {
	incident: Incident;
	onVerify: (data: IncidentVerificationFormData) => void;
	isSubmitting: boolean;
}

export function IncidentVerificationForm({
	incident,
	onVerify,
	isSubmitting,
}: IncidentVerificationFormProps) {
	const t = useTranslations('VerifyForm');
	const form = useForm<FormValues>({
		resolver: zodResolver(formSchema),
		defaultValues: {
			verificationStatus: VerificationStatus.APPROVED,
			incidentType: incident.incidentType || null,
			severity: incident.severity || null,
			notes: '',
			responseNeeded: false,
		},
	});

	const verificationStatus = form.watch('verificationStatus');
	const isRejected = verificationStatus === VerificationStatus.REJECTED;

	function onSubmit(data: FormValues) {
		onVerify({
			action: 'verify',
			verificationStatus: data.verificationStatus as VerificationStatus,
			incidentType: data.incidentType
				? (data.incidentType as IncidentType)
				: undefined,
			severity: data.severity
				? (data.severity as IncidentSeverity)
				: undefined,
			notes: data.notes,
			responseNeeded: data.responseNeeded,
		});
	}

	const incidentTypes = [
		{ value: IncidentType.VEHICLE_COLLISION, label: t('typeVehicleCollision') },
		{ value: IncidentType.FIRE, label: t('typeFire') },
		{ value: IncidentType.PEDESTRIAN_ACCIDENT, label: t('typePedestrian') },
		{ value: IncidentType.DEBRIS_ON_ROAD, label: t('typeDebris') },
		{ value: IncidentType.STOPPED_VEHICLE, label: t('typeStopped') },
		{ value: IncidentType.WRONG_WAY_DRIVER, label: t('typeWrongWay') },
		{ value: IncidentType.OTHER, label: t('typeOther') },
	];

	return (
		<Form {...form}>
			<form onSubmit={form.handleSubmit(onSubmit)} className='space-y-6'>
				<div className='mb-6 space-y-1'>
					<h3 className='text-lg font-medium text-foreground'>
						{t('decision')}
					</h3>
					<p className='text-sm text-muted-foreground'>{t('decisionDesc')}</p>
				</div>

				<div className='grid grid-cols-2 gap-4'>
					<Button
						type='button'
						className={`flex flex-1 flex-row gap-2 border-2 bg-transparent p-4 hover:bg-green-100 dark:hover:bg-green-900/20 ${
							verificationStatus === VerificationStatus.APPROVED
								? 'border-green-500 bg-green-100 dark:bg-green-900/20 text-foreground'
								: 'border-border text-muted-foreground hover:text-foreground'
						}`}
						onClick={() =>
							form.setValue('verificationStatus', VerificationStatus.APPROVED)
						}>
						<CheckCircle2
							className={`h-6 w-6 ${
								verificationStatus === VerificationStatus.APPROVED
									? 'text-green-500'
									: 'text-muted-foreground'
							}`}
						/>
						<span>{t('confirm')}</span>
					</Button>

					<Button
						type='button'
						className={`flex flex-1 flex-row gap-2 border-2 bg-transparent p-4 hover:bg-red-100 dark:hover:bg-red-900/20 ${
							verificationStatus === VerificationStatus.REJECTED
								? 'border-red-500 bg-red-100 dark:bg-red-900/20 text-foreground'
								: 'border-border text-muted-foreground hover:text-foreground'
						}`}
						onClick={() =>
							form.setValue('verificationStatus', VerificationStatus.REJECTED)
						}>
						<XCircle
							className={`h-6 w-6 ${
								verificationStatus === VerificationStatus.REJECTED
									? 'text-red-500'
									: 'text-muted-foreground'
							}`}
						/>
						<span>{t('reject')}</span>
					</Button>
				</div>

				{!isRejected && (
					<>
						<FormField
							control={form.control}
							name='incidentType'
							render={({ field }) => (
								<FormItem>
									<FormLabel>{t('incidentTypeLabel')}</FormLabel>
									<Select
										onValueChange={field.onChange}
										value={field.value || undefined}>
										<FormControl>
											<SelectTrigger className='border-border bg-muted text-foreground focus:ring-blue-500'>
												<SelectValue placeholder={t('selectType')} />
											</SelectTrigger>
										</FormControl>
										<SelectContent className='border-border bg-muted text-foreground'>
											{incidentTypes.map(type => (
												<SelectItem
													key={type.value}
													value={type.value}
													className='hover:bg-accent'>
													{type.label}
												</SelectItem>
											))}
										</SelectContent>
									</Select>
								</FormItem>
							)}
						/>

						<FormField
							control={form.control}
							name='severity'
							render={({ field }) => (
								<FormItem>
									<FormLabel>{t('severityLabel')}</FormLabel>
									<Select
										onValueChange={field.onChange}
										value={field.value || undefined}>
										<FormControl>
											<SelectTrigger className='border-border bg-muted text-foreground focus:ring-blue-500'>
												<SelectValue placeholder={t('selectSeverity')} />
											</SelectTrigger>
										</FormControl>
										<SelectContent className='border-border bg-muted text-foreground'>
											<SelectItem
												value={IncidentSeverity.CRITICAL}
												className='hover:bg-accent'>
												<div className='flex items-center gap-2'>
													<div className='h-2 w-2 rounded-full bg-red-500'></div>
													{t('severityCritical')}
												</div>
											</SelectItem>
											<SelectItem
												value={IncidentSeverity.MAJOR}
												className='hover:bg-accent'>
												<div className='flex items-center gap-2'>
													<div className='h-2 w-2 rounded-full bg-amber-500'></div>
													{t('severityMajor')}
												</div>
											</SelectItem>
											<SelectItem
												value={IncidentSeverity.MINOR}
												className='hover:bg-accent'>
												<div className='flex items-center gap-2'>
													<div className='h-2 w-2 rounded-full bg-blue-500'></div>
													{t('severityMinor')}
												</div>
											</SelectItem>
										</SelectContent>
									</Select>
								</FormItem>
							)}
						/>

						<FormField
							control={form.control}
							name='responseNeeded'
							render={({ field }) => (
								<FormItem className='flex flex-row items-start space-x-3 space-y-0'>
									<FormControl>
										<Checkbox
											checked={field.value}
											onCheckedChange={field.onChange}
											className='border-border data-[state=checked]:bg-blue-600 data-[state=checked]:text-white'
										/>
									</FormControl>
									<div className='space-y-1 leading-none'>
										<FormLabel>{t('responseNeededLabel')}</FormLabel>
										<FormDescription className='text-muted-foreground'>
											{t('responseNeededDesc')}
										</FormDescription>
									</div>
								</FormItem>
							)}
						/>
					</>
				)}

				<FormField
					control={form.control}
					name='notes'
					render={({ field }) => (
						<FormItem>
							<FormLabel>
								{isRejected ? t('rejectionReason') : t('additionalNotes')}
							</FormLabel>
							<FormControl>
								<Textarea
									{...field}
									placeholder={
										isRejected
											? t('rejectionPlaceholder')
											: t('notesPlaceholder')
									}
									className='border-border bg-muted text-foreground placeholder:text-muted-foreground focus:border-blue-500 focus:ring-blue-500'
									rows={4}
								/>
							</FormControl>
						</FormItem>
					)}
				/>

				<Button
					type='submit'
					className={`w-full ${
						isRejected
							? 'bg-red-600 hover:bg-red-700'
							: 'bg-blue-600 hover:bg-blue-700'
					}`}
					disabled={isSubmitting}>
					{isSubmitting ? (
						<>
							<Loader2 className='mr-2 h-4 w-4 animate-spin' />
							{isRejected ? t('rejecting') : t('confirming')}
						</>
					) : (
						<>{isRejected ? t('rejectSubmit') : t('confirmSubmit')}</>
					)}
				</Button>
			</form>
		</Form>
	);
}
