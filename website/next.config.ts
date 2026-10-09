/** @type {import('next').NextConfig} */
const nextConfig = {
  poweredByHeader: false,
  experimental: {
    // Keeps `next dev` from writing hundreds of MB of cache to disk.
    turbopackFileSystemCacheForDev: false,
  },
  async redirects() {
    // The project used to live at gaitguardai.vercel.app; send old links to the new name.
    return [
      {
        source: "/:path*",
        has: [{ type: "host", value: "gaitguardai.vercel.app" }],
        destination: "https://gaitguard-app.vercel.app/:path*",
        permanent: true,
      },
    ];
  },
};

export default nextConfig;
