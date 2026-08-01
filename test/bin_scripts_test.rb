# frozen_string_literal: true

require 'test_helper'

# The developer entry points are shell, and shell fails quietly in ways Ruby
# does not. `bin/ci` shipped reporting failure on a fully passing run because
# bash 3.2 — which is what /bin/bash is on macOS — treats `"${arr[@]}"` on an
# EMPTY array as an unbound variable under `set -u`. Every gate passed, the
# summary printed, and then the script died on the loop that had nothing to
# print.
class BinScriptsTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)
  # bin/ holds both shell and Ruby entry points, neither with an extension,
  # so the interpreter has to come from the shebang.
  SHELLS = %w[sh bash zsh dash].freeze
  SCRIPTS = Dir[File.join(ROOT, 'bin', '*')].select { |path| File.file?(path) }.freeze

  def test_there_are_scripts_to_check
    refute_empty SCRIPTS
  end

  def test_every_script_is_executable
    non_executable = SCRIPTS.reject { |path| File.executable?(path) }

    assert_empty(non_executable.map { |path| relative(path) })
  end

  def test_every_shell_script_parses
    shell_scripts.each do |path|
      assert system('bash', '-n', path, out: File::NULL, err: File::NULL),
             "#{relative(path)} is not valid bash"
    end
  end

  # The regression guard. An array expanded without a length check, in a script
  # running under `set -u`, is the exact shape that broke bin/ci.
  def test_scripts_using_set_u_guard_their_array_expansions
    offenders = shell_scripts.flat_map do |path|
      source = File.read(path)
      next [] unless source.match?(/set -[a-z]*u/)

      unguarded_arrays(source).map { |name| "#{relative(path)}: \"${#{name}[@]}\" without a ${##{name}[@]} guard" }
    end

    assert_empty offenders,
                 "bash 3.2 aborts on an empty array under `set -u`:\n#{offenders.join("\n")}"
  end

  # Exposed so the rule itself is tested, rather than only its effect on the
  # current tree.
  #
  # The guard must be near the loop, not merely present in the file. A
  # file-level check was tried first and failed to catch the real regression,
  # because bin/ci legitimately uses ${#failed[@]} further down for its exit
  # status — so the loop looked guarded while being wide open.
  GUARD_WINDOW = 5

  def self.unguarded_arrays(source)
    lines = source.lines

    lines.each_with_index.filter_map do |line, index|
      name = line[/for\s+\w+\s+in\s+"\$\{(\w+)\[@\]\}"/, 1]
      next unless name
      # Only an array that can actually be empty can trip the quirk. One built
      # from a literal list — `RAILS_VERSIONS=("7.1" "7.2")` — never is, and
      # demanding a guard there would be noise.
      next unless source.match?(/^\s*#{Regexp.escape(name)}=\(\s*\)/)

      preceding = lines[[index - GUARD_WINDOW, 0].max...index].join
      name unless preceding.include?("${##{name}[@]}")
    end.uniq
  end

  def test_the_rule_detects_the_shape_that_broke_bin_ci
    buggy = <<~SH
      set -uo pipefail
      failed=()
      for name in "${failed[@]}"; do
        echo "$name"
      done
    SH

    assert_equal ['failed'], self.class.unguarded_arrays(buggy)
  end

  def test_the_rule_accepts_a_length_guarded_loop
    guarded = <<~SH
      set -uo pipefail
      failed=()
      if [ ${#failed[@]} -ne 0 ]; then
        for name in "${failed[@]}"; do
          echo "$name"
        done
      fi
    SH

    assert_empty self.class.unguarded_arrays(guarded)
  end

  private

  def unguarded_arrays(source) = self.class.unguarded_arrays(source)

  def shell_scripts
    SCRIPTS.select { |path| shell?(path) }
  end

  def shell?(path)
    shebang = File.open(path, &:readline)
    return false unless shebang.start_with?('#!')

    SHELLS.include?(File.basename(shebang.split.last.to_s))
  rescue EOFError
    false
  end

  def relative(path)
    path.delete_prefix("#{ROOT}/")
  end
end
