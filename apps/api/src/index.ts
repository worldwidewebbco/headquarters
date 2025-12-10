import { createHTTPServer } from '@trpc/server/adapters/standalone'
import cors from 'cors'
import { healthRouter } from './routers/health'
import { router } from './trpc'

const appRouter = router({
	health: healthRouter,
})

export type AppRouter = typeof appRouter

const server = createHTTPServer({
	middleware: cors(),
	router: appRouter,
})

const PORT = process.env.PORT ?? 3001

server.listen(PORT)
console.log(`🚀 API server running on http://localhost:${PORT}`)
