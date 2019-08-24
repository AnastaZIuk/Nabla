#define _IRR_STATIC_LIB_
#include <irrlicht.h>

//#include "../src/irr/asset/CBAWMeshWriter.h"
#include <SVertexManipulator.h>

using namespace irr;
using namespace core;

bool quit = false;
//!Same As Last Example
class MyEventReceiver : public IEventReceiver
{
public:

	MyEventReceiver()
	{
	}

	bool OnEvent(const SEvent& event)
	{
        if (event.EventType == irr::EET_KEY_INPUT_EVENT && !event.KeyInput.PressedDown)
        {
            switch (event.KeyInput.Key)
            {
            case irr::KEY_KEY_Q: // switch wire frame mode
                quit = true;
                return true;
            default:
                break;
            }
        }

		return false;
	}

private:
};

class SimpleCallBack : public video::IShaderConstantSetCallBack
{
    int32_t mvpUniformLocation;
    int32_t cameraDirUniformLocation;
    int32_t texUniformLocation[4];
    video::E_SHADER_CONSTANT_TYPE mvpUniformType;
    video::E_SHADER_CONSTANT_TYPE cameraDirUniformType;
    video::E_SHADER_CONSTANT_TYPE texUniformType[4];
public:
    SimpleCallBack() : cameraDirUniformLocation(-1), cameraDirUniformType(video::ESCT_FLOAT_VEC3) {}

    virtual void PostLink(video::IMaterialRendererServices* services, const video::E_MATERIAL_TYPE& materialType, const core::vector<video::SConstantLocationNamePair>& constants)
    {
        for (size_t i=0; i<constants.size(); i++)
        {
            if (constants[i].name=="MVP")
            {
                mvpUniformLocation = constants[i].location;
                mvpUniformType = constants[i].type;
            }
            else if (constants[i].name=="cameraPos")
            {
                cameraDirUniformLocation = constants[i].location;
                cameraDirUniformType = constants[i].type;
            }
        }
    }

    virtual void OnSetConstants(video::IMaterialRendererServices* services, int32_t userData)
    {
        core::vectorSIMDf modelSpaceCamPos;
        modelSpaceCamPos.set(services->getVideoDriver()->getTransform(video::E4X3TS_WORLD_VIEW_INVERSE).getTranslation());
        services->setShaderConstant(&modelSpaceCamPos,cameraDirUniformLocation,cameraDirUniformType,1);
        services->setShaderConstant(services->getVideoDriver()->getTransform(video::EPTS_PROJ_VIEW_WORLD).pointer(),mvpUniformLocation,mvpUniformType,1);
    }

    virtual void OnUnsetMaterial() {}
};


int main()
{
    srand(time(0));
	// create device with full flexibility over creation parameters
	// you can add more parameters if desired, check irr::SIrrlichtCreationParameters
	irr::SIrrlichtCreationParameters params;
	params.Bits = 24; //may have to set to 32bit for some platforms
	params.ZBufferBits = 24; //we'd like 32bit here
	params.DriverType = video::EDT_OPENGL; //! Only Well functioning driver, software renderer left for sake of 2D image drawing
	params.WindowSize = dimension2d<uint32_t>(1280, 720);
	params.Fullscreen = false;
	params.Vsync = true; //! If supported by target platform
	params.Doublebuffer = true;
	params.Stencilbuffer = false; //! This will not even be a choice soon
	IrrlichtDevice* device = createDeviceEx(params);

	if (device == 0)
		return 1; // could not create selected driver.


	video::IVideoDriver* driver = device->getVideoDriver();

    /*SimpleCallBack* cb = new SimpleCallBack();
    video::E_MATERIAL_TYPE newMaterialType = (video::E_MATERIAL_TYPE)driver->getGPUProgrammingServices()->addHighLevelShaderMaterialFromFiles("../mesh.vert",
                                                        "","","", //! No Geometry or Tessellation Shaders
                                                        "../mesh.frag",
                                                        3,video::EMT_SOLID, //! 3 vertices per primitive (this is tessellation shader relevant only
                                                        cb, //! Our Shader Callback
                                                        0); //! No custom user data
    cb->drop();
    */


	scene::ISceneManager* smgr = device->getSceneManager();
	driver->setTextureCreationFlag(video::ETCF_ALWAYS_32_BIT, true);
	scene::ICameraSceneNode* camera =
		smgr->addCameraSceneNodeFPS(0,100.0f,0.01f);
	camera->setPosition(core::vector3df(-4,0,0));
	camera->setTarget(core::vector3df(0,0,0));
	camera->setNearValue(0.01f);
	camera->setFarValue(100.0f);
    smgr->setActiveCamera(camera);
	device->getCursorControl()->setVisible(false);
	MyEventReceiver receiver;
	device->setEventReceiver(&receiver);

	io::IFileSystem* filesystem = device->getFileSystem();
    asset::IAssetManager& am = device->getAssetManager();
/*
    const char* shader_source = R"(#version 430 core
layout (location = 0) in vec4 vPosition;
layout (location = 1) in vec4 vColor;


//aaa
//#include "hejka.glh"
//bbb

struct Hej {
    vec4 col;
    int arr[30];
    uint arr2[8];
};
layout(push_constant) uniform pushConstants {
    float test2;
    Hej hej[2];
} u_pushConstants;


layout (location = 3) out vec4 fColor;
layout (constant_id = 8)  const int SSBO_CNT = 3;
layout (constant_id = 13) const int BUF_SZ = 64;

struct S1
{
    int i1;
    uint i2;
    float f3;
};
struct S2
{
    float f[3];
    S1 h;
};
struct S3
{
    uint i;
    uvec2 u2;
    S2 struct_memb[4];
};
layout(std430, binding = 0, set = 2) restrict buffer Samples {
    vec3 samples[45];
    S3 smembs[2];
}ssbo[SSBO_CNT];
layout(std140, binding = 4) uniform Controls
{
    mat4 MVP;
};

void main() {
    gl_Position = MVP*vPosition*ssbo[1].samples[44].xxyy*u_pushConstants.test2;
    fColor = vColor;
})";
*/
    const asset::IGLSLCompiler* glslcomp = am.getGLSLCompiler();
    asset::ISpecializationInfo* vs_specInfo = new asset::ISpecializationInfo({}, nullptr, "main", asset::ESS_VERTEX);
    asset::ISpecializationInfo* fs_specInfo = new asset::ISpecializationInfo({}, nullptr, "main", asset::ESS_VERTEX);
    asset::ICPUShader* vs_unspec = glslcomp->createSPIRVFromGLSL(filesystem->createAndOpenFile("../mesh.vert"), asset::ESS_VERTEX, "main", "../mesh.vert");
    asset::ICPUSpecializedShader* vs = new asset::ICPUSpecializedShader(vs_unspec, vs_specInfo);
    vs_specInfo->drop();
    asset::ICPUShader* fs_unspec = glslcomp->createSPIRVFromGLSL(filesystem->createAndOpenFile("../mesh.frag"), asset::ESS_VERTEX, "main", "../mesh.frag");
    asset::ICPUSpecializedShader* fs = new asset::ICPUSpecializedShader(fs_unspec, fs_specInfo);
    fs_specInfo->drop();

    asset::ICPUSpecializedShader* cpushaders[]{ vs, fs };
    auto gpushaders = driver->getGPUObjectsFromAssets(cpushaders, cpushaders+2);

    std::array<video::IGPUSpecializedShader*, 5u> pipeline{ {gpushaders[0],nullptr,nullptr,nullptr,gpushaders[1]} };

	// from Criss:
	// here i'm testing baw mesh writer and loader
	// (import from .stl/.obj, then export to .baw, then import from .baw :D)
	// Seems to work for those two simple meshes, but need more testing!


	//! Test Loading of Obj
    asset::IAssetLoader::SAssetLoadParams lparams;
    asset::ICPUMesh* cpumesh = static_cast<asset::ICPUMesh*>(device->getAssetManager().getAsset("../../media/extrusionLogo_TEST_fixed.stl", lparams));
	// export mesh
    /*asset::CBAWMeshWriter::WriteProperties bawprops;
    asset::IAssetWriter::SAssetWriteParams wparams(cpumesh, asset::EWF_COMPRESSED, 0.f, 0, nullptr, &bawprops);
    device->getAssetManager().writeAsset("extrusionLogo_TEST_fixed.baw", wparams);
	// end export

	// import .baw mesh (test)
    cpumesh = static_cast<asset::ICPUMesh*>(device->getAssetManager().getAsset("extrusionLogo_TEST_fixed.baw", lparams));
	// end import
    */
    if (cpumesh)
    {
        video::IGPUMesh* gpumesh = driver->getGPUObjectsFromAssets(&cpumesh, (&cpumesh)+1)[0];
        smgr->addMeshSceneNode(gpumesh)->setMaterialType(pipeline);
        gpumesh->drop();
    }

    cpumesh = static_cast<asset::ICPUMesh*>(device->getAssetManager().getAsset("../../media/cow.obj", lparams));
	// export mesh
    /*wparams.rootAsset = cpumesh;
    device->getAssetManager().writeAsset("cow.baw", wparams);
	// end export

	// import .baw mesh (test)
	cpumesh = static_cast<asset::ICPUMesh*>(device->getAssetManager().getAsset("cow.baw", lparams));
	// end import
    */
    if (cpumesh)
    {
        video::IGPUMesh* gpumesh = driver->getGPUObjectsFromAssets(&cpumesh, (&cpumesh)+1)[0];
        smgr->addMeshSceneNode(gpumesh,0,-1,core::vector3df(3.f,1.f,0.f))->setMaterialType(pipeline);
        gpumesh->drop();
    }


	uint64_t lastFPSTime = 0;

	while(!quit && device->run())
	//if (device->isWindowActive())
	{
		driver->beginScene(true, true, video::SColor(255,0,0,255) );

        //! This animates (moves) the camera and sets the transforms
        //! Also draws the meshbuffer
        smgr->drawAll();

		driver->endScene();

		// display frames per second in window title
		uint64_t time = device->getTimer()->getRealTime();
		if (time-lastFPSTime > 1000)
		{
			std::wostringstream sstr;
			sstr << L"Builtin Nodes Demo - Irrlicht Engine FPS:" << driver->getFPS() << " PrimitvesDrawn:" << driver->getPrimitiveCountDrawn();

			device->setWindowCaption(sstr.str().c_str());
			lastFPSTime = time;
		}
	}
    
	device->drop();

	return 0;
}
