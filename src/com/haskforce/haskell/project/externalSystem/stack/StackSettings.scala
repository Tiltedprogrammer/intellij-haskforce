package com.haskforce.haskell.project.externalSystem.stack

import com.intellij.openapi.externalSystem.settings.{AbstractExternalSystemSettings, ExternalSystemSettingsListener}
import com.intellij.openapi.project.Project

final class StackSettings(
  project: Project
) extends AbstractExternalSystemSettings[
  StackSettings,
  ProjectSettings,
  StackSettingsListener
  ](StackSettingsListener.TOPIC, project) {

  override def subscribe(listener: ExternalSystemSettingsListener[ProjectSettings]): Unit =
      project.getMessageBus
        .connect(project)
        .subscribe[ExternalSystemSettingsListener[ProjectSettings]](
          StackSettingsListener.TOPIC, listener
        )

  override def copyExtraSettingsFrom(settings: StackSettings): Unit = ???

  override def checkSettings(old: ProjectSettings, current: ProjectSettings): Unit = ???
}
