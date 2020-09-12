// Copyright (C) 2020 - AnastaZIuk
// This file is part of the "IrrlichtBAW" engine.
// For conditions of distribution and use, see copyright notice in irrlicht.h

#ifndef __IRR_I_DITHER_H_INCLUDED__
#define __IRR_I_DITHER_H_INCLUDED__

#include "irr/core/core.h"
#include "irr/asset/ICPUImage.h"
#include "irr/asset/ICPUImageView.h"

namespace irr
{
    namespace asset
    {
        //! Abstract Data Type for CDither class
        /*
            Holds top level state for dithering and
            provides some methods for proper another
            base CRTP class implementation - CDither
        */

        class IDither
        {
            public:
                virtual ~IDither() {}

                //! Base state interface class
                /*
                    Holds texel range of an image
                */

                class IState
                {
                    public:
                        virtual ~IState() {}

                        struct TexelRange
                        {
                            VkOffset3D	offset = { 0u,0u,0u };
                            VkExtent3D	extent = { 0u,0u,0u };
                        };
                };

                virtual float pGet(const IState* state, const core::vectorSIMDu32& pixelCoord, const int32_t& channel) = 0;
        };
    }
}

#endif // __IRR_I_DITHER_H_INCLUDED__