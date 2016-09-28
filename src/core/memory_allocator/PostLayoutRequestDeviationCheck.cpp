/*
 * Copyright (c) 2015 2016, Intel Corporation
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   * Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *   * Neither the name of Intel Corporation nor the names of its contributors
 *     may be used to endorse or promote products derived from this software
 *     without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Rule that checks that layout is within acceptable deviation from the request
 */

#include "PostLayoutRequestDeviationCheck.h"

#include <LogEnterExit.h>
#include <core/exceptions/NvmExceptionBadRequest.h>
#include <utility.h>

#define ACCEPTED_PERCENT_DEVIATION 10

// using macro to avoid ambiguous overload call to abs function
#define ABSOLUTEDIFFERENCE(X, Y) (X > Y) ? (X - Y) : (Y - X)

core::memory_allocator::PostLayoutRequestDeviationCheck::PostLayoutRequestDeviationCheck()
{
	LogEnterExit logging(__FUNCTION__, __FILE__, __LINE__);
}

core::memory_allocator::PostLayoutRequestDeviationCheck::~PostLayoutRequestDeviationCheck()
{
	LogEnterExit logging(__FUNCTION__, __FILE__, __LINE__);
}

double core::memory_allocator::PostLayoutRequestDeviationCheck::findPercentDeviation(
		NVM_UINT64 expectedValue, NVM_UINT64 observedValue)
{
	LogEnterExit logging(__FUNCTION__, __FILE__, __LINE__);
	int deviation = ABSOLUTEDIFFERENCE(observedValue, expectedValue);

	return (double)100.0 * (deviation)/expectedValue;
}

bool core::memory_allocator::PostLayoutRequestDeviationCheck::layoutDeviationIsWithinBounds(
		double percentDeviation)
{
	LogEnterExit logging(__FUNCTION__, __FILE__, __LINE__);
	return (percentDeviation <= ACCEPTED_PERCENT_DEVIATION);
}

void core::memory_allocator::PostLayoutRequestDeviationCheck::checkIfMemoryCapacityLayoutIsAcceptable(
		const struct MemoryAllocationRequest& request,
		const MemoryAllocationLayout& layout)
{
	LogEnterExit logging(__FUNCTION__, __FILE__, __LINE__);

	if (request.getMemoryModeCapacityGiB())
	{
		double percentDeviation =
				findPercentDeviation(request.getMemoryModeCapacityGiB(), layout.memoryCapacity);
		if ((layout.memoryCapacity == 0)  ||
				(!layoutDeviationIsWithinBounds(percentDeviation)))
		{
			throw core::NvmExceptionUnacceptableLayoutDeviation();
		}
	}
}

void core::memory_allocator::PostLayoutRequestDeviationCheck::checkAppDirectCapacityLayoutIsAcceptable(
		const struct MemoryAllocationRequest& request,
		const MemoryAllocationLayout& layout)
{
	LogEnterExit logging(__FUNCTION__, __FILE__, __LINE__);

	if (request.getAppDirectCapacityGiB() > 0)
	{
		NVM_UINT64 layoutAppDirectCapacity = getNonReservedAppDirectCapacityGiBFromLayout(request, layout);
		double percentDeviation = findPercentDeviation(request.getAppDirectCapacityGiB(),
						layoutAppDirectCapacity);
		if (!layoutDeviationIsWithinBounds(percentDeviation))
		{
			throw core::NvmExceptionUnacceptableLayoutDeviation();
		}
	}
}

NVM_UINT64 core::memory_allocator::PostLayoutRequestDeviationCheck::getReservedAppDirectCapacityGiB(
		const struct MemoryAllocationRequest& request)
{
	LogEnterExit logging(__FUNCTION__, __FILE__, __LINE__);

	NVM_UINT64 reservedAppDirectCapacity = 0;
	if (reservedDimmIsAppDirect(request))
	{
		Dimm reservedDimm = request.getReservedDimm();
		reservedAppDirectCapacity = B_TO_GiB(reservedDimm.capacityBytes);
	}

	return reservedAppDirectCapacity;
}

bool core::memory_allocator::PostLayoutRequestDeviationCheck::reservedDimmIsAppDirect(
		const struct MemoryAllocationRequest& request)
{
	LogEnterExit logging(__FUNCTION__, __FILE__, __LINE__);

	return (request.hasReservedDimm() &&
			request.getReservedDimmCapacityType() == RESERVE_DIMM_APP_DIRECT_X1);
}

NVM_UINT64 core::memory_allocator::PostLayoutRequestDeviationCheck::getNonReservedAppDirectCapacityGiBFromLayout(
		const struct MemoryAllocationRequest& request, const MemoryAllocationLayout& layout)
{
	LogEnterExit logging(__FUNCTION__, __FILE__, __LINE__);

	NVM_UINT64 reservedAppDirectCapacity = getReservedAppDirectCapacityGiB(request);

	return layout.appDirectCapacity - reservedAppDirectCapacity;
}

void core::memory_allocator::PostLayoutRequestDeviationCheck::verify(
		const struct MemoryAllocationRequest& request,
		const struct MemoryAllocationLayout &layout)
{
	LogEnterExit logging(__FUNCTION__, __FILE__, __LINE__);

	checkIfMemoryCapacityLayoutIsAcceptable(request, layout);
	checkAppDirectCapacityLayoutIsAcceptable(request, layout);
}
