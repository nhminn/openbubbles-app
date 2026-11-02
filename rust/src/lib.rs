use std::{
    path::Path,
    sync::{LazyLock, Once},
};

use flexi_logger::{opt_format, Age, Cleanup, Criterion, FileSpec, Logger, Naming, WriteMode};
use tokio::runtime::Runtime;
use log::info;


uniffi::setup_scaffolding!();

pub static RUNTIME: LazyLock<tokio::runtime::Runtime> = LazyLock::new(|| {
    info!("creating runner");
    tokio::runtime::Builder::new_multi_thread()
        .worker_threads(1)
        .thread_name("tokio-rustpush")
        .enable_all()
        .build().unwrap()
});

pub mod bbhwinfo {
    include!(concat!(env!("OUT_DIR"), "/bbhwinfo.rs"));
}

/// Install the process-global Rust logger.
///
/// The logger is shared by every Dart isolate that loads this library, so this
/// function must be idempotent: a second call (for example from the background
/// sync isolate calling `doFirstTimeInit` again) must not panic or replace the
/// existing logger.
pub fn init_logger(path: &Path) {
    static INIT: Once = Once::new();

    INIT.call_once(|| {
        #[cfg(target_os = "android")]
        let system = android_logger::AndroidLogger::new(
            android_logger::Config::default().with_max_level(log::LevelFilter::Debug),
        );
        #[cfg(not(target_os = "android"))]
        let system = {
            if std::env::var("RUST_LOG").is_err() {
                std::env::set_var("RUST_LOG", "debug");
            }
            pretty_env_logger::formatted_builder().build()
        };

        let file_logger = Logger::try_with_str("debug").and_then(|logger| {
            logger
                .log_to_file(FileSpec::default().directory(path.join("logs")).suppress_timestamp())
                .append()
                .format(opt_format)
                .cleanup_in_background_thread(false)
                .rotate(
                    Criterion::AgeOrSize(Age::Day, 1024 * 1024 * 10 /* 10 MB */),
                    Naming::Numbers,
                    Cleanup::KeepLogFiles(1),
                )
                .write_mode(WriteMode::BufferAndFlush)
                .build()
        });

        // Never panic on logger setup: file logging is a convenience, and the
        // system logger alone keeps the app usable (e.g. read-only data dir).
        let mut loggers: Vec<Box<dyn log::Log>> = vec![Box::new(system)];
        let mut logger_error = None;
        match file_logger {
            Ok((logger, _handle)) => loggers.push(logger),
            Err(err) => logger_error = Some(err),
        }

        // Another logger may already be installed when this library is loaded
        // into a long-lived process (or when init runs more than once). Keep the
        // existing logger instead of aborting the caller.
        if let Err(err) = multi_log::MultiLogger::init(loggers, log::Level::Trace) {
            info!("Rust logger already initialized: {err:?}");
        }
        if let Some(err) = logger_error {
            log::error!("Unable to initialize the file logger: {err:?}");
        }
    });
}

mod native;
pub mod api;
mod keystore;
mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */
