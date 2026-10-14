import os
import subprocess
import sys
import tempfile
from datetime import UTC, datetime
from pathlib import Path


def validate(zsh: str, path: Path) -> bool:
    result = subprocess.run(
        [zsh, "-f", "-c", 'fc -R "$1"', "history-check", str(path)],
        capture_output=True,
        check=False,
    )
    # History can contain secrets; never forward zsh diagnostics to the journal.
    return result.returncode == 0 and not result.stderr


def main():
    path = Path(sys.argv[1])
    zsh = sys.argv[2]
    if not path.exists():
        return
    if path.is_symlink() or not path.is_file():
        raise RuntimeError("History must be a regular file, not a symlink")

    original = path.read_bytes()
    if b"\0" not in original:
        if not validate(zsh, path):
            raise RuntimeError("Unknown history corruption; file left unchanged")
        print("History check passed")
        return

    fd, name = tempfile.mkstemp(prefix=".history-repair-", dir=path.parent)
    temporary = Path(name)
    try:
        with os.fdopen(fd, "wb") as stream:
            _ = stream.write(original.replace(b"\0", b""))
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, path.stat().st_mode & 0o777)
        if not validate(zsh, temporary):
            raise RuntimeError("Repair validation failed; file left unchanged")

        backup = path.with_name(
            path.name + ".backup-" + datetime.now(UTC).strftime("%Y%m%d-%H%M%S-%fZ")
        )
        backup_fd = os.open(backup, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(backup_fd, "wb") as stream:
            _ = stream.write(original)
            stream.flush()
            os.fsync(stream.fileno())

        # Do not overwrite commands appended while the check was running.
        if path.read_bytes() != original:
            raise RuntimeError("History changed during repair; file left unchanged")
        os.replace(temporary, path)
        print(f"Removed {original.count(bytes([0]))} NUL bytes; backup: {backup}")
    finally:
        temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
