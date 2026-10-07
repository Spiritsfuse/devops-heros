# print current date - date
# hostname and username - hostname whoami who w
# process ps
# add process info inside a file name process.log --> > process.log

# print name,roll_no, comment 

## use variables, take input, create file and directory 

```bash
current_date=$(date)
echo $current_date

echo $hostname
echo $whoami
ps > process.log
read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no
read -p "Enter your comment: " comment

echo "My name is $name"
echo "My roll number is $roll_no"
echo "My comment is: $comment"
```

#### 💡 Command Breakdown (cmd-explained):
- `current_date=$(date)`: Command substitution. Executes the binary `/bin/date` in a subshell and assigns its string output to the environment variable `current_date`.
- `echo $current_date`: Dereferences and prints the value of variable `current_date` to standard output (`stdout`).
- `hostname`: Outputs the system's DNS network node hostname.
- `whoami`: Displays the effective username of the currently logged-in user running the shell session.
- `ps > process.log`: Runs the process snapshot utility `ps` and uses the `>` redirection operator to overwrite standard output (`FD 1`) directly into the file `process.log`.
- `read -p "..." var`: Pauses script execution, displays the interactive text prompt (`-p`), reads input from standard input (`stdin`), and stores the result in variable `var`.

---

### Core DevOps Shell Scripting Patterns

```bash
# 1. Positional Arguments & Exit Status Verification
echo "Script name: $0, First argument: $1, Total arguments: $#"
if [ $? -eq 0 ]; then
  echo "Previous command succeeded"
else
  echo "Command failed with exit code $?" >&2
fi

# 2. Pipes & Stream Redirection (Filter & Count)
ps aux | grep "nginx" | grep -v "grep" | wc -l

# 3. Loops and File Iteration
for file in *.log; do
  [ -e "$file" ] || continue
  gzip -9 "$file"
done

# 4. Functions with Local Scope
backup_data() {
  local src_dir="$1"
  local dest_dir="$2"
  mkdir -p "$dest_dir"
  cp -r "$src_dir"/* "$dest_dir"
  return 0
}
```

#### 💡 Command Breakdown (cmd-explained):
- `$0, $1, $#`: Built-in bash positional parameters. `$0` is the executing script name, `$1` to `$9` are passed command-line arguments, `$#` gives the total count of arguments passed.
- `$?`: Special shell variable storing the numeric exit status of the most recently executed command (`0` = success, `1-255` = error).
- `>&2`: Redirects stdout (`FD 1`) to standard error (`FD 2`), ensuring error messages are separated from normal program output pipelines.
- `ps aux | grep ... | wc -l`: Unix pipeline. Standard output of `ps` flows into standard input of `grep`. `grep -v "grep"` inverts the match to strip out the grep process itself, and `wc -l` counts matching lines.
- `for file in *.log; do ... done`: Bash globbing loop that iterates over all files ending in `.log`.
- `local src_dir="$1"`: Restricts variable scope strictly to the function body, preventing global variable pollution in larger automation scripts.

---

### 📚 Tech Jargons Demystified:
- **Shebang (`#!/bin/bash`)**: The first line of a script indicating to the Linux kernel loader which interpreter binary must be spawned to parse and execute the script instructions.
- **File Descriptors (FD 0, 1, 2)**: Standard streams in Linux:
  - `0` (stdin): Standard input (keyboard / input pipe).
  - `1` (stdout): Standard output (terminal screen / redirection `>`).
  - `2` (stderr): Standard error (error stream / redirection `2>`).
- **Exit Status Code (`$?`)**: Every Linux binary returns an integer upon termination. `0` universally denotes success; any non-zero value (`1`, `2`, `127`) signals a specific runtime fault or command not found.
- **Pipes (`|`)**: Inter-process communication (IPC) channel in the Linux kernel linking the stdout buffer of the left command directly into the stdin buffer of the right command in memory, without creating intermediate temporary files on disk.
- **Command Substitution (`$()`)**: Spawns an ephemeral subshell, runs the enclosed command, and injects its standard output back into the script string. Replaces legacy backticks (`` `command` ``).