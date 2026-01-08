# Homebrew Cask formula for OfficeViewer
# To use this formula, create a tap repository:
#   1. Create repo: github.com/younggglcy/homebrew-tap
#   2. Copy this file to: Casks/officeviewer.rb
#   3. Users can then install via: brew tap younggglcy/tap && brew install --cask officeviewer

cask "officeviewer" do
  version "0.1.1"
  sha256 "REPLACE_WITH_ACTUAL_SHA256"

  url "https://github.com/younggglcy/OfficeViewer/releases/download/v#{version}/OfficeViewer-#{version}.dmg"
  name "OfficeViewer"
  desc "Open Office files and view their XML structure"
  homepage "https://github.com/younggglcy/OfficeViewer"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "OfficeViewer.app"

  zap trash: [
    "~/Library/Caches/OfficeViewer",
    "~/Library/Preferences/name.younggglcy.OfficeViewer.plist",
  ]
end
