/*
  Warnings:

  - You are about to drop the column `cctvId` on the `incidents` table. All the data in the column will be lost.
  - You are about to drop the `cctvs` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "incidents" DROP CONSTRAINT "incidents_cctvId_fkey";

-- DropIndex
DROP INDEX "incidents_cctvId_idx";

-- AlterTable
ALTER TABLE "incidents" DROP COLUMN "cctvId";

-- DropTable
DROP TABLE "cctvs";
