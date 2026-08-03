import { prisma } from './prisma'

/**
 * A ride's vehicle may be a company "pool" vehicle (Vehicle.ownerBranchId set).
 * Returns true if an employee from `requestingBranchId` may book a seat on it:
 *  - the vehicle isn't a pool vehicle at all (open to everyone, as today), or
 *  - it belongs to the requester's own branch, or
 *  - the owning branch has granted the requester's branch a fleet-sharing
 *    partnership (BranchPartnership).
 */
export async function canAccessVehicleFleet(
  vehicleOwnerBranchId: bigint | null,
  requestingBranchId: bigint | null,
): Promise<boolean> {
  if (!vehicleOwnerBranchId) return true
  if (requestingBranchId !== null && vehicleOwnerBranchId === requestingBranchId) return true
  if (requestingBranchId === null) return false

  const partnership = await prisma.branchPartnership.findFirst({
    where: { ownerBranchId: vehicleOwnerBranchId, partnerBranchId: requestingBranchId, isActive: true },
  })
  return !!partnership
}
