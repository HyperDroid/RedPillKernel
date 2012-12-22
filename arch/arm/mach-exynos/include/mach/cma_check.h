/*
 * Functions to check given physical addresses against the CMA memory blocks.
 *
 * Author: Andrei F.
 * Credit: Gokhan Moral for his alternative version of the original patch
 *
 */

#include <linux/cma.h>

#define STATIC_CMA_REGION_COUNT (4)

struct simple_cma_descriptor {
  const char   *name;
  dma_addr_t    start;
  size_t    size;
};

extern struct cma_region *p_regions_normal;
extern struct cma_region *p_regions_secure;

extern struct simple_cma_descriptor static_cma_regions[];
extern size_t size_static_cma_regions;

static inline void cma_static_region_add(const char *name, dma_addr_t start, size_t size)
{
	int i;

	pr_info("[%s] adding [%s] (0x%08x)-(0x%08x)\n",
		__func__, name, start, size);

	if(size_static_cma_regions == STATIC_CMA_REGION_COUNT)
		return;

	i = size_static_cma_regions;

	static_cma_regions[i].name = name;
	static_cma_regions[i].start = start;
	static_cma_regions[i].size = size;

	size_static_cma_regions++;
}

static inline int check_memspace_against_cma_blocks(int start, int size)
{
	struct cma_region *r;
	struct simple_cma_descriptor *sr;
	size_t i;
	const char *name;

	for(r = p_regions_normal; r->size != 0; r++) {
		if(start >= r->start && (start + size) <= (r->start + r->size)){
			name = r->name;
			goto cma_match;
		}
	}

	for(r = p_regions_secure; r->size != 0; r++) {
		if(start >= r->start && (start + size) <= (r->start + r->size)){
			name = r->name;
			goto cma_match;
		}
	}

	for(i = 0; i < size_static_cma_regions; i++) {
		sr = &static_cma_regions[i];
		if(start >= sr->start && (start + size) <= (sr->start + sr->size)){
			name = sr->name;
			goto cma_match;
		}
	}


	pr_info("[cma_check] Unauthorized access to 0x%08x/0x%08x\n",
		 start, size);

	return 1;

cma_match:
	pr_info("[cma_check] Accessing space 0x%08x/0x%08x for '%s'\n",
		 start, size, name);
	
	return 0;
}
