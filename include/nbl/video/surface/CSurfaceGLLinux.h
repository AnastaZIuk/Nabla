#ifndef __NBL_C_SURFACE_GL_LINUX_H_INCLUDED__
#define __NBL_C_SURFACE_GL_LINUX_H_INCLUDED__

#include "nbl/core/compile_config.h"

#ifdef _NBL_PLATFORM_LINUX_

#include "nbl/video/surface/ISurfaceLinux.h"
#include "nbl/video/surface/ISurfaceGL.h"

namespace nbl {
namespace video
{

class CSurfaceGLLinux final : public ISurfaceLinux, public ISurfaceGL
{
public:
    explicit CSurfaceGLLinux(SCreationParams&& params) : ISurfaceLinux(std::move(params)), ISurfaceGL(params.window)
    {

    }
};

}
}

#endif

#endif