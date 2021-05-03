#ifndef __NBL_I_ASYNC_QUEUE_DISPATCHER_H_INCLUDED__
#define __NBL_I_ASYNC_QUEUE_DISPATCHER_H_INCLUDED__

#include <atomic>
#include "nbl/system/IThreadHandler.h"
#include "nbl/core/Types.h"
#include "nbl/core/math/intutil.h"

namespace nbl {
namespace system
{

namespace impl
{
    class IAsyncQueueDispatcherBase
    {
    public:
        struct request_base_t
        {
            std::mutex mtx;
            // wait on this for result to be ready
            std::condition_variable cvar;
            std::atomic_bool ready = false;

            std::unique_lock<std::mutex> lock()
            {
                return std::unique_lock<std::mutex>(mtx);
            }

            std::unique_lock<std::mutex> wait()
            {
                std::unique_lock<std::mutex> lk(mtx);
                cvar.wait(lk, [this]() { return this->ready.load(); });
                return lk;
            }
        };
    };
}

/**
* Provided RequestType may optionally define 2 member functions:
* void lock();
* void unlock();
* lock() will be called just before processing the request, and unlock() will be called just after processing the request.
* Those are to enable safe external write access to the request struct for user-defined purposes.
*/
template <typename CRTP, typename RequestType, uint32_t BufferSize = 256u, typename InternalStateType = void>
class IAsyncQueueDispatcher : public IThreadHandler<CRTP, InternalStateType>, public impl::IAsyncQueueDispatcherBase
{
    static_assert(std::is_base_of_v<impl::IAsyncQueueDispatcherBase::request_base_t, RequestType>, "Request type must derive from request_base_t!");
    static_assert(BufferSize>0u, "BufferSize must not be 0!");
    static_assert(core::isPoT(BufferSize), "BufferSize must be power of two!");

    using base_t = IThreadHandler<CRTP, InternalStateType>;
    friend base_t;

    constexpr static inline uint32_t MaxRequestCount = BufferSize;

    using atomic_counter_t = std::atomic_uint64_t;
    using counter_t = atomic_counter_t::value_type;

    RequestType request_pool[MaxRequestCount];
    atomic_counter_t cb_begin = 0u;
    atomic_counter_t cb_end = 0u;

    static inline counter_t wrapAround(counter_t x)
    {
        constexpr counter_t Mask = static_cast<counter_t>(BufferSize) - static_cast<counter_t>(1);
        return x & Mask;
    }

public:
    using mutex_t = typename base_t::mutex_t;
    using lock_t = typename base_t::lock_t;
    using cvar_t = typename base_t::cvar_t;
    using internal_state_t = typename base_t::internal_state_t;

    using request_t = RequestType;

    ///////
    // Required accessible methods of class being CRTP parameter:

    //void init(internal_state_t* state); // required only in case of custom internal state

    //void exit(internal_state_t* state); // optional, no `state` parameter in case of no internal state

    //void request_impl(request_t& req, ...); // `...` are parameteres forwarded from request()
    //bool process_request_predicate(const request_t& req); // optional, always true if not provided
    //void process_request(request_t& req, internal_state_t& state); // no `state` parameter in case of no internal state
    ///////

    template <typename... Args>
    request_t& request(Args&&... args)
    {
        auto virtualIx = cb_end++;
        auto safe_begin = virtualIx<MaxRequestCount ? static_cast<counter_t>(0) : (virtualIx-MaxRequestCount+1u);

        for (counter_t old_begin; (old_begin = cb_begin.load()) < safe_begin; )
        {
#if __cplusplus >= 202002L
            cb_begin.wait(old_begin);
#else
            std::this_thread::yield();
#endif
        }

        const auto r_id = wrapAround(virtualIx);

        request_t& req = request_pool[r_id];
        auto lk = req.lock();
        req.ready = false;
        static_cast<CRTP*>(this)->request_impl(req, std::forward<Args>(args)...);
        // unlock request after we've written everything into it
        lk.unlock();
        // wake up queue thread
        base_t::m_cvar.notify_one();

        return req;
    }

protected:
    bool process_request_predicate(const request_t& req)
    {
        return true;
    }

private:
    template <typename... Args>
    void work(lock_t& lock, Args&&... optional_internal_state)
    {
        static_assert(sizeof...(optional_internal_state) <= 1u, "How did this happen");

        auto r_id = cb_begin++;
#if __cplusplus >= 202002L
        cb_begin.notify_one();
#endif
        r_id = wrapAround(r_id);

        request_t& req = request_pool[r_id];
        auto lk = req.lock();

        if (static_cast<CRTP*>(this)->process_request_predicate(req))
        {
            static_cast<CRTP*>(this)->process_request(req, optional_internal_state...);
        }

        req.ready = true;
        req.cvar.notify_all();
    }

    bool wakeupPredicate() const { return (cb_begin != cb_end); }
    bool continuePredicate() const { return (cb_begin != cb_end); }
};

}
}

#endif
