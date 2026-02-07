<?php

namespace Espo\Custom\Classes\AppParams;

use Espo\Core\ApplicationState;
use Espo\Core\Acl;
use Espo\ORM\EntityManager;

/**
 * App param that ensures the ImportLeadsFromCsv scheduled job exists.
 * This runs on every app load and creates the job if missing.
 */
class CsvLeadImportScheduledJobCheck
{
    private const SCHEDULED_JOB_NAME = 'Import Leads from CSV';
    private const SCHEDULED_JOB_JOB = 'ImportLeadsFromCsv';
    private const SCHEDULED_JOB_SCHEDULING = '* * * * *';

    public function __construct(
        private EntityManager $entityManager,
        private ApplicationState $applicationState,
        private Acl $acl
    ) {}

    public function get(): bool
    {
        // Only check for admin users to avoid performance impact
        if (!$this->applicationState->isLogged()) {
            return false;
        }

        if (!$this->acl->checkScope('Admin')) {
            return true; // Return true, nothing to do for non-admins
        }

        // Check if scheduled job exists
        $existingJob = $this->entityManager
            ->getRDBRepository('ScheduledJob')
            ->where([
                'job' => self::SCHEDULED_JOB_JOB,
                'deleted' => false,
            ])
            ->findOne();

        if ($existingJob) {
            return true;
        }

        // Create the scheduled job
        $scheduledJob = $this->entityManager->getNewEntity('ScheduledJob');
        $scheduledJob->set([
            'name' => self::SCHEDULED_JOB_NAME,
            'job' => self::SCHEDULED_JOB_JOB,
            'status' => 'Active',
            'scheduling' => self::SCHEDULED_JOB_SCHEDULING,
        ]);

        $this->entityManager->saveEntity($scheduledJob);

        return true;
    }
}
