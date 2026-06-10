'use client';

import * as React from 'react';
import {
	Command,
	ScanSearch,
	Siren,
	AlertTriangle,
	Clock,
} from 'lucide-react';

import { NavMain } from '@/components/nav-main';
import { NavUser } from '@/components/nav-user';
import { LocaleSwitcher } from '@/components/locale-switcher';
import { useTranslations } from 'next-intl';
import {
	Sidebar,
	SidebarContent,
	SidebarFooter,
	SidebarHeader,
	SidebarMenu,
	SidebarMenuButton,
	SidebarMenuItem,
} from '@/components/ui/sidebar';
import { useSession } from 'next-auth/react';

export function AppSidebar({ ...props }: React.ComponentProps<typeof Sidebar>) {
	const { data: session } = useSession();
	const t = useTranslations('Nav');

	const data = {
		user: {
			name: session?.user?.name || 'Guest',
			email: session?.user?.email || 'guest@example.com',
			avatar: session?.user?.image || '/avatars/default-avatar.png',
		},
		navDetection: [
			{
				title: t('accidentDetection'),
				url: '/',
				icon: ScanSearch,
				isactive: true,
			},
		],
		navIncident: [
			{
				title: t('pendingVerification'),
				url: '/Pending_Verification',
				icon: Clock,
			},
			{
				title: t('ongoingIncidents'),
				url: '/Ongoing_Incidents',
				icon: AlertTriangle,
			},
		],
		navTraffic: [
			{
				title: t('trafficAid'),
				url: '/Traffic_Aid',
				icon: Siren,
			},
		],
	};

	return (
		<Sidebar variant='inset' {...props}>
			<SidebarHeader>
				<SidebarMenu>
					<SidebarMenuItem>
						<SidebarMenuButton size='lg' asChild>
							<a href='#'>
								<div className='flex aspect-square size-8 items-center justify-center rounded-lg bg-sidebar-primary text-sidebar-primary-foreground'>
									<Command className='size-4' />
								</div>
								<div className='grid flex-1 text-left text-sm leading-tight'>
									<span className='truncate font-semibold'>Crash Detection ML</span>
									<span className='truncate text-xs'>{t('subtitle')}</span>
								</div>
							</a>
						</SidebarMenuButton>
					</SidebarMenuItem>
				</SidebarMenu>
			</SidebarHeader>
			<SidebarContent>
				<NavMain heading={t('groupDetection')} items={data.navDetection} />
				<NavMain heading={t('groupIncident')} items={data.navIncident} />
				<NavMain heading={t('groupTraffic')} items={data.navTraffic} />
			</SidebarContent>
			<SidebarFooter>
				<div className='flex items-center justify-end px-1 pb-1'>
					<LocaleSwitcher />
				</div>
				<NavUser user={data.user} />
			</SidebarFooter>
		</Sidebar>
	);
}
