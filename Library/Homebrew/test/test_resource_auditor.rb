require "testing_env"
require "dev-cmd/audit"

class ResourceAuditorTests < Homebrew::TestCase
  def mock_resource
    stub(name: "",
         version: 1,
         checksum: "",
         url: "",
         mirrors: [
           "http://badexample.com/foo-1.0.tgz",
         ],
         using: nil,
         specs: "")
  end

  def offline_resource_auditor
    ResourceAuditor.new(mock_resource)
  end

  def online_resource_auditor
    ResourceAuditor.new(mock_resource, online: true)
  end

  def test_resource_auditor_offline_by_default
    assert_equal false, offline_resource_auditor.instance_variable_get(:@online)
  end

  def test_resource_auditor_online
    assert_equal true, online_resource_auditor.instance_variable_get(:@online)
  end

  def test_audit_urls_for_bad_mirror
    ra = online_resource_auditor
    raises_exception = -> { raise ErrorDuringExecution.new("", []) }
    ra.stub :nostdout, raises_exception do
      ra.audit_urls
      assert_equal ["http://badexample.com/foo-1.0.tgz is not reachable "\
        "(curl exit code #{$?.exitstatus})"], ra.problems
    end
  end
end
