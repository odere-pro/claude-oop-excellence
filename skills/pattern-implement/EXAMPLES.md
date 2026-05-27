# Pattern Implementation Examples

## Table of contents

- [Builder pattern](#builder-pattern) — Before/after for complex object construction
- [Chain of Responsibility](#chain-of-responsibility) — Before/after for validation pipeline
- [Decorator pattern](#decorator-pattern) — Before/after for composable wrappers
- [Strategy pattern](#strategy-pattern) — Before/after for conditional algorithm selection

## Builder pattern

### Before

```typescript
// 170 lines of nested object literal
generate(config: Config): string {
  const settings = {
    permissions: {
      allow: permissionsForPackageManager(config.project.package_manager),
      deny: ['Bash(rm -rf /)', 'Bash(rm -rf ~*)', /* ... 14 more ... */],
    },
    thinkingEnabled: true,
    effortLevel: 'auto',
    hooks: {
      PreToolUse: [
        { matcher: 'Edit|Write', hooks: [{ type: 'command', command: 'bash env-guard.sh 2>&1' }] },
        { matcher: 'Bash(git commit*)', hooks: [{ type: 'command', command: 'bash secret-scan.sh 2>&1' }] },
        // ... 7 more hook entries ...
      ],
      // ... 3 more hook events ...
    },
  };
  return JSON.stringify(settings, null, 2) + '\n';
}
```

### After

```typescript
class SettingsBuilder {
  private permissions = { allow: [] as string[], deny: [] as string[] };
  private hooks: Record<string, HookEntry[]> = {};
  private flags: Record<string, unknown> = {};

  allow(...patterns: string[]): this {
    this.permissions.allow.push(...patterns);
    return this;
  }

  deny(...patterns: string[]): this {
    this.permissions.deny.push(...patterns);
    return this;
  }

  hook(event: string, matcher: string, type: 'command' | 'prompt', value: string): this {
    const entry = { matcher, hooks: [{ type, [type === 'command' ? 'command' : 'prompt']: value }] };
    (this.hooks[event] ??= []).push(entry);
    return this;
  }

  flag(key: string, value: unknown): this {
    this.flags[key] = value;
    return this;
  }

  build(): object {
    return { permissions: this.permissions, ...this.flags, hooks: this.hooks };
  }
}

// Usage: each hook is one readable line
generate(config: Config): string {
  const builder = new SettingsBuilder()
    .allow(...permissionsForPackageManager(config.project.package_manager))
    .deny('Bash(rm -rf /)', 'Bash(rm -rf ~*)')
    .flag('thinkingEnabled', true)
    .hook('PreToolUse', 'Edit|Write', 'command', 'bash env-guard.sh 2>&1')
    .hook('PreToolUse', 'Bash(git commit*)', 'command', 'bash secret-scan.sh 2>&1');
  return JSON.stringify(builder.build(), null, 2) + '\n';
}
```

**Why it works**: Each hook is one fluent call. Sections are testable in isolation. Adding hooks requires one line, not navigating 170 lines of nesting.

## Chain of Responsibility

### Before

```typescript
validate(args: string[]): ValidationResult {
  const result: ValidationResult = { errors: [], warnings: [] };

  this.logger.step('Branch naming convention');
  const branch = this.getCurrentBranch();
  const issueNumber = this.validateBranchName(branch, result);

  this.logger.step('Conventional commit format');
  this.validateCommitMessages(baseRef, result);

  this.logger.step('Memory file completeness');
  if (issueNumber) {
    this.validateMemoryFiles(issueNumber, result);
  }

  this.logger.step('Secret scan');
  this.validateSecrets(baseRef, result);

  this.logger.step('Test coverage check');
  this.validateTestCoverage(baseRef, result);

  return result;
}
```

### After

```typescript
interface ValidationCheck {
  name: string;
  run(ctx: ValidationContext, result: ValidationResult): void;
}

interface ValidationContext {
  branch: string;
  baseRef: string;
  issueNumber: string | null;
  runner: CommandRunner;
  logger: Logger;
}

class BranchNameCheck implements ValidationCheck {
  name = 'Branch naming convention';
  run(ctx: ValidationContext, result: ValidationResult): void { /* ... */ }
}

// Usage: checks are a composable list
private checks: ValidationCheck[] = [
  new BranchNameCheck(),
  new CommitMessageCheck(),
  new MemoryFileCheck(),
  new SecretScanCheck(),
  new TestCoverageCheck(),
];

validate(args: string[]): ValidationResult {
  const ctx = this.buildContext(args);
  const result: ValidationResult = { errors: [], warnings: [] };
  for (const check of this.checks) {
    this.logger.step(check.name);
    check.run(ctx, result);
  }
  return result;
}
```

**Why it works**: Adding a new validation check is one class + one array entry. No orchestrator modification needed.

## Decorator pattern

### Before

```typescript
class FileWriter {
  writeIfChanged(path: string, content: string): boolean {
    // Always writes to disk — no dry-run, no logging, no testability
  }
}

class GeneratorPipeline {
  private writer = new FileWriter(); // Hardcoded, not injectable
}
```

### After

```typescript
interface Writer {
  writeIfChanged(path: string, content: string): boolean;
  ensureDirectories(paths: string[]): void;
  readonly stats: { changed: number; unchanged: number; total: number };
}

class FileWriter implements Writer {
  /* ... existing implementation ... */
}

class DryRunWriter implements Writer {
  constructor(
    private inner: Writer,
    private logger: Logger,
  ) {}

  writeIfChanged(path: string, content: string): boolean {
    this.logger.detail(`[dry-run] would write: ${path} (${content.length} bytes)`);
    return false;
  }
  // ...
}

// Composable: new DryRunWriter(new FileWriter(), logger)
class GeneratorPipeline {
  constructor(
    private writer: Writer,
    private logger: Logger = new Logger(),
  ) {}
}
```

**Why it works**: DryRunWriter enables pure pipeline tests. LoggingWriter adds timing. Decorators compose without modifying FileWriter.

## Strategy pattern

### Before

```typescript
function permissionsForPackageManager(pm: string): string[] {
  const base = ['Bash(gh issue *)', 'Bash(git *)'];
  switch (pm) {
    case 'bun':
      return [...base, 'Bash(bun *)', 'Bash(~/.bun/bin/bun *)'];
    case 'npm':
      return [...base, 'Bash(npm run *)', 'Bash(npx *)'];
    case 'yarn':
      return [...base, 'Bash(yarn *)', 'Bash(npx *)'];
    default:
      return [...base, `Bash(${pm} *)`];
  }
}
```

### After

```typescript
interface PackageManagerStrategy {
  permissions(): string[];
}

const PM_STRATEGIES: Record<string, PackageManagerStrategy> = {
  bun: { permissions: () => ['Bash(bun *)', 'Bash(~/.bun/bin/bun *)'] },
  npm: { permissions: () => ['Bash(npm run *)', 'Bash(npx *)'] },
  yarn: { permissions: () => ['Bash(yarn *)', 'Bash(npx *)'] },
};

function permissionsForPackageManager(pm: string): string[] {
  const base = ['Bash(gh issue *)', 'Bash(git *)'];
  const strategy = PM_STRATEGIES[pm] ?? { permissions: () => [`Bash(${pm} *)`] };
  return [...base, ...strategy.permissions()];
}
```

**Why it works**: Adding `deno` or `pnpm` is one map entry. Each strategy is independently testable. No switch modification needed.
