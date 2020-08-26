# frozen_string_literal: true

require "spec_helper"

describe LameSitemapper::Cli do
  describe "run" do
    context "when called with no parameters" do
      let(:out) { StringIO.new }

      let(:cli) { described_class.new(out, []) }

      it "exits cleanly and write usage to output" do
        expect(lambda { cli.run }).to exit_with_code(0)

        expect(out.string).to eq(cli.opt_parser.to_s)
      end
    end

    context "when called with -h parameter" do
      let(:out) { StringIO.new }

      let(:cli) { described_class.new(out, ["-h"]) }

      it "exits cleanly and write usage to output" do
        expect(lambda { cli.run }).to exit_with_code(0)

        expect(out.string).to eq(cli.opt_parser.to_s)
      end
    end

    context "when called with -v parameter" do
      let(:out) { StringIO.new }

      let(:cli) { described_class.new(out, ["-v"]) }

      it "exits cleanly and write version number to output" do
        expect(lambda { cli.run }).to exit_with_code(0)

        expect(out.string).to eq(LameSitemapper::VERSION + "\n")
      end
    end

    context "when called with non-existing parameter" do
      let(:out) { StringIO.new }

      let(:cli) { described_class.new(out, ["--never-ever-to-be-used"]) }

      it "exits cleanly and return message containing invalid parameter used" do
        expect(lambda { cli.run }).to exit_with_code(0)

        expect(out.string).to match(/^invalid option: --never-ever-to-be-used/)
      end
    end
  end
end
