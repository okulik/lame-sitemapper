require "spec_helper"

module SiteMapper
  describe Cli do
    describe "main" do
      context "when called with no parameters" do
        let(:out) { StringIO.new }
        let(:cli) { Cli.new(out, []) }
        it "should exit cleanly and write usage to output" do
          lambda { cli.run }.should exit_with_code(0)
          out.string.should eq cli.opt_parser.to_s
        end
      end

      context "when called with -h parameters" do
        let(:out) { StringIO.new }
        let(:cli) { Cli.new(out, ["-h"]) }
        it "should exit cleanly and write usage to output" do
          lambda { cli.run }.should exit_with_code(0)
          out.string.should eq cli.opt_parser.to_s
        end
      end

      context "when called with -v parameters" do
        let(:out) { StringIO.new }
        let(:cli) { Cli.new(out, ["-v"]) }
        it "should exit cleanly and write version number to output" do
          lambda { cli.run }.should exit_with_code(0)
          out.string.chomp.should eq Version::STRING
        end
      end

      context "when called with non-existing parameter" do
        let(:out) { StringIO.new }
        let(:cli) { Cli.new(out, ["--never-ever-to-be-used"]) }
        it "should exit cleanly and return message containing invalid parameter used" do
          lambda { cli.run }.should exit_with_code(0)
          out.string.should match /^invalid option: --never-ever-to-be-used/
        end
      end
    end
  end
end
