<?php

namespace Espo\Custom\Classes\ConsoleCommands;

use Espo\Core\Console\Command;
use Espo\Core\Console\Command\Params;
use Espo\Core\Console\IO;
use Espo\ORM\EntityManager;

/**
 * Console command to ensure all custom scheduled jobs exist.
 * 
 * Usage: php bin/command ensure-scheduled-jobs
 * 
 * Run this after deployment to create any missing scheduled jobs.
 */
class EnsureScheduledJobs implements Command
{
    private const JOBS = [
        [
            'name' => 'Import Leads from CSV',
            'job' => 'ImportLeadsFromCsv',
            'scheduling' => '*/5 * * * *',
        ],
    ];

    public function __construct(
        private EntityManager $entityManager
    ) {}

    public function run(Params $params, IO $io): void
    {
        $io->writeLine('Checking scheduled jobs...');

        $created = 0;
        $existing = 0;

        foreach (self::JOBS as $jobConfig) {
            $exists = $this->entityManager
                ->getRDBRepository('ScheduledJob')
                ->where([
                    'job' => $jobConfig['job'],
                    'deleted' => false,
                ])
                ->findOne();

            if ($exists) {
                $io->writeLine("  ✓ '{$jobConfig['name']}' already exists");
                $existing++;
                continue;
            }

            $scheduledJob = $this->entityManager->getNewEntity('ScheduledJob');
            $scheduledJob->set([
                'name' => $jobConfig['name'],
                'job' => $jobConfig['job'],
                'status' => 'Active',
                'scheduling' => $jobConfig['scheduling'],
            ]);

            $this->entityManager->saveEntity($scheduledJob);

            $io->writeLine("  + Created '{$jobConfig['name']}'");
            $created++;
        }

        $io->writeLine('');
        $io->writeLine("Done. Created: {$created}, Already existed: {$existing}");
    }
}
