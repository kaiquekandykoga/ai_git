# frozen_string_literal: true

require_relative "../test_helper"

class TestSecrets < Test::Unit::TestCase
  def scan(staged, diff = "")
    AIGit::Secrets.scan(staged, diff)
  end

  def test_clean_change_has_no_findings
    findings = scan("lib/ai_git.rb\n", "+++ b/lib/ai_git.rb\n+puts \"hello\"\n")

    assert_empty findings[:blocking]
    assert_empty findings[:warnings]
  end

  def test_flags_risky_paths
    [".env\n", ".env.production\n", "config/id_rsa\n", "certs/server.pem\n",
     "config/credentials\n", "config/secrets.yml\n"].each do |staged|
      assert_not_empty scan(staged)[:blocking], "#{staged.strip} should be flagged"
    end
  end

  def test_flags_key_material_in_added_lines
    diff = "+-----BEGIN RSA PRIVATE KEY-----\n"
    assert_not_empty scan("lib/a.rb\n", diff)[:blocking]
  end

  def test_flags_aws_and_github_tokens
    assert_not_empty scan("a.rb\n", "+key = AKIAIOSFODNN7EXAMPLE\n")[:blocking]
    assert_not_empty scan("a.rb\n", "+token = ghp_0123456789abcdefghijklmnopqrstuvwx\n")[:blocking]
  end

  def test_ignores_secrets_on_removed_lines
    assert_empty scan("a.rb\n", "--- a/a.rb\n-key = AKIAIOSFODNN7EXAMPLE\n")[:blocking]
  end

  def test_generic_assignment_only_warns
    findings = scan("a.rb\n", "+password = \"correcthorsebattery\"\n")

    assert_empty findings[:blocking]
    assert_not_empty findings[:warnings]
  end
end
