import React from 'react';
import { Badge } from '@/components/ui/badge';
import {
	AlertTriangle,
	AlertCircle,
	Info,
	Clock,
	CheckCircle,
	XCircle,
} from 'lucide-react';
import { VerificationStatus, IncidentSeverity } from '@prisma/client';
import {
	getVerificationStatusColor,
	getSeverityColor,
} from '@/lib/incident-helper';
import { useTranslations } from 'next-intl';

interface VerificationStatusBadgeProps {
	status: VerificationStatus | null;
	className?: string;
}

export function VerificationStatusBadge({
	status,
	className = '',
}: VerificationStatusBadgeProps) {
	const getIcon = () => {
		switch (status) {
			case VerificationStatus.PENDING:
				return <Clock className='mr-1 h-3 w-3' />;
			case VerificationStatus.APPROVED:
				return <CheckCircle className='mr-1 h-3 w-3' />;
			case VerificationStatus.REJECTED:
				return <XCircle className='mr-1 h-3 w-3' />;
			default:
				return null;
		}
	};

	const t = useTranslations('Status');
	const getLabel = () => {
		switch (status) {
			case VerificationStatus.PENDING:
				return t('pending');
			case VerificationStatus.APPROVED:
				return t('verified');
			case VerificationStatus.REJECTED:
				return t('rejected');
			default:
				return t('unknown');
		}
	};

	return (
		<Badge className={`${getVerificationStatusColor(status)} ${className}`}>
			{getIcon()}
			{getLabel()}
		</Badge>
	);
}

interface SeverityBadgeProps {
	severity: IncidentSeverity | null;
	className?: string;
}

export function SeverityBadge({
	severity,
	className = '',
}: SeverityBadgeProps) {
	const getIcon = () => {
		switch (severity) {
			case IncidentSeverity.CRITICAL:
				return <AlertTriangle className='mr-1 h-3 w-3' />;
			case IncidentSeverity.MAJOR:
				return <AlertCircle className='mr-1 h-3 w-3' />;
			case IncidentSeverity.MINOR:
				return <Info className='mr-1 h-3 w-3' />;
			default:
				return null;
		}
	};

	const t = useTranslations('Status');
	const getLabel = () => {
		switch (severity) {
			case IncidentSeverity.CRITICAL:
				return t('critical');
			case IncidentSeverity.MAJOR:
				return t('major');
			case IncidentSeverity.MINOR:
				return t('minor');
			default:
				return t('unknown');
		}
	};

	return (
		<Badge className={`${getSeverityColor(severity)} ${className}`}>
			{getIcon()}
			{getLabel()}
		</Badge>
	);
}
