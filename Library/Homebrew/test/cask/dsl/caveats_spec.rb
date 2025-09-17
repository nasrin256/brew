# frozen_string_literal: true

require "test/cask/dsl/shared_examples/base"

RSpec.describe Cask::DSL::Caveats, :cask do
  subject(:caveats) { described_class.new(cask) }

  let(:cask) { Cask::CaskLoader.load(cask_path("basic-cask")) }
  let(:dsl) { caveats }

  it_behaves_like Cask::DSL::Base

  # TODO: add tests for Caveats DSL methods

  describe "#requires_rosetta" do
    let(:cask) { instance_double(Cask::Cask, requires_rosetta: true) }

    it "shows Rosetta caveat on ARM architecture" do
      allow(Homebrew::SimulateSystem).to receive(:current_arch).and_return(:arm)
      caveats.eval_caveats do
        requires_rosetta
      end
      expect(caveats.to_s).to include("requires Rosetta 2 to be installed")
    end

    it "does not show Rosetta caveat on Intel architecture" do
      allow(Homebrew::SimulateSystem).to receive(:current_arch).and_return(:intel)
      caveats.eval_caveats do
        requires_rosetta
      end
      expect(caveats.to_s).not_to include("requires Rosetta 2 to be installed")
    end

    it "does not show Rosetta caveat when requires_rosetta is false" do
      allow(cask).to receive(:requires_rosetta).and_return(false)
      allow(Homebrew::SimulateSystem).to receive(:current_arch).and_return(:arm)
      caveats.eval_caveats do
        requires_rosetta
      end
      expect(caveats.to_s).not_to include("requires Rosetta 2 to be installed")
    end

    it "automatically adds Rosetta caveat when requires_rosetta field is true on ARM" do
      allow(Homebrew::SimulateSystem).to receive(:current_arch).and_return(:arm)
      # Don't call requires_rosetta explicitly - it should be added automatically
      result = caveats.to_s
      expect(result).to include("requires Rosetta 2 to be installed")
    end

    it "does not automatically add Rosetta caveat when requires_rosetta field is true on Intel" do
      allow(Homebrew::SimulateSystem).to receive(:current_arch).and_return(:intel)
      # Don't call requires_rosetta explicitly - it should not be added automatically on Intel
      result = caveats.to_s
      expect(result).not_to include("requires Rosetta 2 to be installed")
    end

    it "tracks when requires_rosetta caveat is used" do
      allow(Homebrew::SimulateSystem).to receive(:current_arch).and_return(:arm)
      caveats.eval_caveats do
        requires_rosetta
      end
      expect(caveats.used_built_in_caveat?(:requires_rosetta)).to be true
    end

    it "can exclude requires_rosetta from serialized caveats" do
      allow(Homebrew::SimulateSystem).to receive(:current_arch).and_return(:arm)
      caveats.eval_caveats do
        requires_rosetta
      end
      
      full_text = caveats.to_s
      excluded_text = caveats.to_s_excluding(:requires_rosetta)
      
      expect(full_text).to include("requires Rosetta 2 to be installed")
      expect(excluded_text).not_to include("requires Rosetta 2 to be installed")
    end
  end

  describe "#kext" do
    let(:cask) { instance_double(Cask::Cask) }

    it "points to System Preferences on macOS Monterey and earlier" do
      allow(MacOS).to receive(:version).and_return(MacOSVersion.new("12"))
      caveats.eval_caveats do
        kext
      end
      expect(caveats.to_s).to include("System Preferences → Security & Privacy → General")
    end

    it "points to System Settings on macOS Ventura and later" do
      allow(MacOS).to receive(:version).and_return(MacOSVersion.new("13"))
      caveats.eval_caveats do
        kext
      end
      expect(caveats.to_s).to include("System Settings → Privacy & Security")
    end
  end
end
