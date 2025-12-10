import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
	transpilePackages: ['@hq/shared', '@hq/ui'],
}

export default nextConfig
