<?php

namespace Espo\Custom\Hooks\CsvLeadImport;

use Espo\Core\Hook\Hook\AfterSave;
use Espo\ORM\Entity;
use Espo\ORM\EntityManager;
use Espo\ORM\Repository\Option\SaveOptions;

/**
 * Hook to ensure the scheduled job exists when a CsvLeadImport is saved.
 */
class EnsureScheduledJob implements AfterSave
{
    private const SCHEDULED_JOB_NAME = 'Import Leads from CSV';
    private const SCHEDULED_JOB_JOB = 'ImportLeadsFromCsv';
    private const SCHEDULED_JOB_SCHEDULING = '* * * * *'; // Every 1 minute

    public function __construct(
        private EntityManager $entityManager
    ) {}

    public function afterSave(Entity $entity, SaveOptions $options): void
    {
        $this->ensureScheduledJobExists();
    }

    private function ensureScheduledJobExists(): void
    {
        // Check if scheduled job already exists
        $existingJob = $this->entityManager
            ->getRDBRepository('ScheduledJob')
            ->where([
                'job' => self::SCHEDULED_JOB_JOB,
                'deleted' => false,
            ])
            ->findOne();

        if ($existingJob) {
            return;
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
    }
}
