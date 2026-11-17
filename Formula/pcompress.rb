class Pcompress < Formula
  desc "Parallel compressor and archiver with deduplication and encryption"
  homepage "https://codeberg.org/gregburd/pcompress"
  # Release tarball: includes the bundled lz4/zstd/libbsc/libarchive sources
  # (git submodules) that GitHub's generated archives omit.
  url "https://github.com/gburd/pcompress/releases/download/v4.3.1/pcompress-4.3.1.tar.gz"
  sha256 "80bfe8fc5403978de873388762e28dbd327da935929f35f0e2bb8c743771e27d"
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

    # The library: installed header, pkg-config file, and the fd API.
    (testpath/"t.c").write <<~C
      #include <pcompress/pcompress.h>
      int main(void) {
        pc_ctx_t *c = pc_new();
        int rv = pc_compress_fd(c, 0, 1);
        pc_free(c);
        return rv != 0;
      }
    C
    flags = shell_output("pkgconf --cflags --libs libpcompress").split
    system ENV.cc, "t.c", "-o", "t", *flags
    system "./t < in.txt > lib.pz"
    system "#{bin}/pcompress -d -p < lib.pz > lib.out"
    assert_equal (testpath/"in.txt").read, (testpath/"lib.out").read
  end
end
