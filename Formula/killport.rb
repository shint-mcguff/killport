class Killport < Formula
  desc "Free up a port by killing whatever is listening on it"
  homepage "https://github.com/shint-mcguff/killport"
  url "https://github.com/shint-mcguff/killport/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "6802bc903df2a19747331b722969c59c1995389c72d8802872efc2f0de4a0253"
  license "MIT"

  depends_on xcode: ["14.0", :build]
  depends_on :macos

  def install
    system "swift", "build", "--disable-sandbox", "-c", "release"
    bin.install ".build/release/killport"
  end

  test do
    assert_equal "0.1.0", shell_output("#{bin}/killport --version").strip
    # Nothing of ours listens on a high random port: killport exits 2.
    shell_output("#{bin}/killport 59999", 2)
  end
end
