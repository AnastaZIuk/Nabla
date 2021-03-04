#ifndef __NBL_I_THREAD_HANDLER_H_INCLUDED__
#define __NBL_I_THREAD_HANDLER_H_INCLUDED__

#include <mutex>
#include <condition_variable>
#include <thread>

namespace nbl {
namespace system
{

// Usage:
/*
* class MyThreadHandler : public IThreadHandler<SomeInternalStateType> { .... };
* 
* MyThreadHandler handler;
* std::thread thread(&MyThreadHandler::thread, &handler);
* //...
* //... communicate with the thread using your methods (see note at the end of this section)), thread will sleep until wakeupPredicate() returns true
* //...
* handler.terminate(thread);
* After this handler can be safely destroyed.
* Every method playing around with object's state shared with the thread must begin with line: `auto raii_handler = createRAIIDisptachHandler();`!
*/
template <typename CRTP, typename InternalStateType = void>
class IThreadHandler
{
private:
#define _NBL_IMPL_MEMBER_FUNC_PRESENCE_CHECKER(member_func_name)\
    class has_##member_func_name\
    {\
        using true_type = uint32_t;\
        using false_type = uint64_t;\
    \
        template <typename T>\
        static true_type& test(decltype(&T::member_func_name));\
        static false_type& test(...);\
    \
    public:\
        static inline constexpr bool value = (sizeof(test<CRTP>(0)) == sizeof(true_type));\
    };

    _NBL_IMPL_MEMBER_FUNC_PRESENCE_CHECKER(init)
    _NBL_IMPL_MEMBER_FUNC_PRESENCE_CHECKER(exit)

#undef _NBL_IMPL_MEMBER_FUNC_PRESENCE_CHECKER

protected:
    using mutex_t = std::mutex;
    using cvar_t = std::condition_variable;
    using lock_t = std::unique_lock<mutex_t>;

    static inline constexpr bool has_internal_state = !std::is_void_v<InternalStateType>;
    using internal_state_t = std::conditional_t<has_internal_state, InternalStateType, int>;

    struct raii_dispatch_handler_t
    {
        raii_dispatch_handler_t(lock_t&& _lk, cvar_t& _cv) : lk(std::move(lk)), cv(_cv) {}
        ~raii_dispatch_handler_t()
        {
            lk.unlock();
            cv.notify_one();
        }

    private:
        lock_t lk;
        cvar_t& cv;
    };

    inline lock_t createLock() { return lock_t{ m_mutex }; }
    inline raii_dispatch_handler_t createRAIIDispatchHandler() { return raii_dispatch_handler_t(createLock(), m_cvar); }

    // Required accessible methods of class being CRTP parameter:

    //internal_state_t init(); // required only in case of custom internal state
    //bool wakeupPredicate() const;
    //bool continuePredicate() const;

    // no `state` parameter in case of no internal state
    // lock is locked at the beginning of this function and must be locked at the exit
    //void work(lock_t& lock, internal_state_t& state);

    //void exit(internal_state_t& state); // optional, no `state` parameter in case of no internal state

private:
    inline internal_state_t init_impl()
    {
        static_assert(has_internal_state == has_init::value, "Custom internal state require implementation of init() method!");

        if constexpr (has_internal_state)
        {
            return static_cast<CRTP*>(this)->init();
        }
        else
        {
            return 0;
        }
    }

    void terminate()
    {
        auto lock = createLock();
        m_quit = true;
        lock.unlock();
        m_cvar.notify_one();

        if (m_thread.joinable())
            m_thread.join();
    }

public:
    IThreadHandler() :
        m_thread(&IThreadHandler<CRTP, InternalStateType>::thread, this)
    {

    }

    void thread()
    {
        CRTP* this_ = static_cast<CRTP*>(this);

        auto state = init_impl();

        auto lock = createLock();

        do {
            m_cvar.wait(lock, [this_, &m_quit] { return this_->wakeupPredicate() || m_quit; });

            if (this_->continuePredicate() && !m_quit)
            {
                if constexpr (has_internal_state)
                {
                    this_->work(lock, state);
                }
                else
                {
                    this_->work(lock);
                }
            }
        } while (!m_quit);

        if constexpr (has_exit::value)
        {
            if constexpr (has_internal_state)
            {
                this_->exit(state);
            }
            else
            {
                this_->exit();
            }
        }
    }

    ~IThreadHandler()
    {
        terminate(m_thread);
    }

private:
    mutex_t m_mutex;
    cvar_t m_cvar;
    bool m_quit = false;

    // Must be last member!
    std::thread m_thread;
};

}
}


#endif