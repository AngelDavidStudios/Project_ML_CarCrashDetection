'use client';

import * as React from 'react';
import { Languages, Check } from 'lucide-react';
import { useLocale } from 'next-intl';
import { useRouter } from 'next/navigation';
import { useTransition } from 'react';

import { Button } from '@/components/ui/button';
import {
	DropdownMenu,
	DropdownMenuContent,
	DropdownMenuItem,
	DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { setLocale } from '@/app/actions/locale';
import { locales, localeNames, type Locale } from '@/i18n/config';

export function LocaleSwitcher() {
	const activeLocale = useLocale() as Locale;
	const router = useRouter();
	const [isPending, startTransition] = useTransition();

	const onSelect = (locale: Locale) => {
		if (locale === activeLocale) return;
		startTransition(async () => {
			await setLocale(locale);
			router.refresh();
		});
	};

	return (
		<DropdownMenu>
			<DropdownMenuTrigger asChild>
				<Button variant='outline' size='icon' disabled={isPending}>
					<Languages className='h-[1.2rem] w-[1.2rem]' />
					<span className='sr-only'>{localeNames[activeLocale]}</span>
				</Button>
			</DropdownMenuTrigger>
			<DropdownMenuContent align='end'>
				{locales.map(locale => (
					<DropdownMenuItem
						key={locale}
						onClick={() => onSelect(locale)}
						className='flex items-center justify-between gap-4'>
						{localeNames[locale]}
						{locale === activeLocale && <Check className='h-4 w-4' />}
					</DropdownMenuItem>
				))}
			</DropdownMenuContent>
		</DropdownMenu>
	);
}
