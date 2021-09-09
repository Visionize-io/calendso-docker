FROM node:14-alpine as deps

RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY calendso/package.json calendso/yarn.lock ./
COPY calendso/prisma prisma
RUN yarn install --frozen-lockfile

FROM node:14-alpine as builder
WORKDIR /app
COPY calendso .
COPY --from=deps /app/node_modules ./node_modules
RUN yarn build
# RUN yarn install --production --ignore-scripts --prefer-offline
ENV DATABASE_URL postgres://ooktvzbguuefhy:a13e3629d21eb43ccefd99c4d0b42a02a3c3cda1cd66a9c0efff490a5008ef40@ec2-34-254-69-72.eu-west-1.compute.amazonaws.com:5432/d671v866paso9s
RUN npx prisma db push --accept-data-loss && yarn db-seed

FROM node:14-alpine as runner
WORKDIR /app
ENV NODE_ENV production

COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/lib ./lib
COPY .env ./.env
COPY  scripts scripts
EXPOSE 3000
CMD ["/app/scripts/start.sh"]
