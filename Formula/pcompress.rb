class Pcompress < Formula
  desc "Parallel compressor and archiver with deduplication and encryption"
  homepage "https://codeberg.org/gregburd/pcompress"
  # Release tarball: includes the bundled lz4/zstd/libbsc/libarchive sources
  # (git submodules) that GitHub's generated archives omit.
  url "https://github.com/gburd/pcompress/releases/download/v4.0.2/pcompress-4.0.2.tar.gz"
  sha256 "9d624f7ee877553d64bf0f4015630dee567b305815d295b39b57b7bcc75d6010"
  license "LGPL-3.0-or-later"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build
  depends_on "libomp"
  depends_on "openssl@3"

  uses_from_macos "bzip2"
  uses_from_macos "zlib"

  def install
    # ./config is a hand-written script, not autoconf.
    system "./config", "--prefix=#{prefix}", "--portable", "--disable-wavpack",
                       "--with-openssl=#{formula_opt_prefix("openssl@3")}"
    system "make"
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/pcompress -V")
    (testpath/"in.txt").write("Hello, pcompress! " * 4096)
    system bin/"pcompress", "-c", "zstd", "-l", "6", testpath/"in.txt"
    system bin/"pcompress", "-d", testpath/"in.txt.pz", testpath/"out.txt"
    assert_equal (testpath/"in.txt").read, (testpath/"out.txt").read
  end
end
