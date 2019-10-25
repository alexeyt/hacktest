/*
 *  Copyright (c) 2018-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the MIT license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

namespace Facebook\HackTest\_Private;

use namespace HH\Lib\{Dict, Str};
use namespace HH\Lib\Experimental\IO;
use namespace Facebook\HackTest;

abstract class CLIOutputHandler {
  <<__LateInit>> private dict<HackTest\TestResult, int> $resultCounts;
  <<__LateInit>> private vec<HackTest\ErrorProgressEvent> $errors;

  abstract public function writeProgressAsync(
    <<__AcceptDisposable>> IO\WriteHandle $handle,
    \Facebook\HackTest\ProgressEvent $e,
  ): Awaitable<void>;

  final private function reset(): void {
    $this->resultCounts = Dict\fill_keys(HackTest\TestResult::getValues(), 0);
    $this->errors = vec[];
  }

  final protected function logEvent(HackTest\ProgressEvent $e): void {
    if ($e is HackTest\TestRunStartedProgressEvent) {
      $this->reset();
      return;
    }

    if ($e is HackTest\TestFinishedProgressEvent) {
      $this->resultCounts[$e->getResult()]++;
    }

    if ($e is HackTest\ErrorProgressEvent) {
      $this->errors[] = $e;
      if (!$e is HackTest\TestFinishedProgressEvent) {
        $this->resultCounts[HackTest\TestResult::ERROR]++;
      }
    }
  }

  final public function getResultCounts(): dict<HackTest\TestResult, int> {
    return $this->resultCounts;
  }

  final protected function getErrors(): vec<HackTest\ErrorProgressEvent> {
    return $this->errors;
  }

  final protected function getMessageHeaderForErrorDetails(
    int $message_num,
    HackTest\ErrorProgressEvent $ev,
  ): string {
    if (!$ev is HackTest\TestFinishedWithExceptionProgressEvent) {
      if ($ev is HackTest\ClassProgressEvent) {
        return Str\format("\n\n%d) %s\n", $message_num, $ev->getClassname());
      }
      if ($ev is HackTest\FileProgressEvent) {
        return Str\format("\n\n%d) %s\n", $message_num, $ev->getPath());
      }
      return "\n\n".$message_num.")\n";
    }

    $row = $ev->getDataProviderRow();
    if ($row is nonnull) {
      return Str\format(
        "\n\n%d) %s::%s with data set #%s\n",
        $message_num,
        $ev->getClassname(),
        $ev->getTestMethod(),
        (string)$row[0],
      );
    } else {
      return Str\format(
        "\n\n%d) %s::%s\n",
        $message_num,
        $ev->getClassname(),
        $ev->getTestMethod(),
      );
    }
  }
}