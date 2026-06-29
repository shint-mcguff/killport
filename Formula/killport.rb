class Killport < Formula
  desc "Free up a port by killing whatever is listening on it"
  homepage "https://github.com/shint-mcguff/killport"
  url "https://github.com/shint-mcguff/killport/releases/download/v0.1.0/killport-v0.1.0-universal-macos.tar.gz"
  sha256 "6c8b369beaf879a75e526e5de34ad60dfb2a376e84214db5bf3df64b930c4392"
  license "MIT"
  version "0.1.0"

  depends_on :macos

  def install
    bin.install "killport"
  end

  test do
    assert_equal "0.1.0", shell_output("#{bin}/killport --version").strip
    # Nothing of ours listens on a high random port: killport exits 2.
    shell_output("#{bin}/killport 59999", 2)
  end
end
