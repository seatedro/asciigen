class Asciigen < Formula
  desc "Converts images to ascii art"
  homepage "https://github.com/seatedro/asciigen"
  version "1.0.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/seatedro/asciigen/releases/download/v#{version}/asciigen-aarch64-macos.tar.gz"
      sha256 "aed7063ef2bbdaa7318b4ee8ecc91bb9641ffc560b8c2d779da5ac38c81cdd8d"
    else
      url "https://github.com/seatedro/asciigen/releases/download/v#{version}/asciigen-x86_64-macos.tar.gz"
      sha256 "54e954176e5d1a6c783d570a7b38403aeb19cb148cb128961a6937363f1b2b07"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/seatedro/asciigen/releases/download/v#{version}/asciigen-aarch64-linux.tar.gz"
      sha256 "f49031560ba84ae4c09a2006a5081f81b72d34321490d3f002528f7b83c017df"
    else
      url "https://github.com/seatedro/asciigen/releases/download/v#{version}/asciigen-x86_64-linux.tar.gz"
      sha256 "660a476554c0c670a1559d57a1c71f5d12fb5f8c2d0dcc062e259b7208d9044c"
    end
  end

  def install
    bin.install "asciigen"
  end

  test do
    system "#{bin}/asciigen", "--version"
  end
end
