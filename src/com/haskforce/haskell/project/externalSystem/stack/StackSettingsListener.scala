package com.haskforce.haskell.project.externalSystem.stack

import java.util

import com.intellij.openapi.externalSystem.settings.ExternalSystemSettingsListener
import com.intellij.util.messages.Topic

final class StackSettingsListener
  extends ExternalSystemSettingsListener[ProjectSettings] {

  override def onProjectRenamed(oldName: String, newName: String): Unit = ???

  override def onProjectsLinked(settings: util.Collection[ProjectSettings]): Unit = ???

  override def onProjectsUnlinked(linkedProjectPaths: util.Set[String]): Unit = ???

  override def onUseAutoImportChange(currentValue: Boolean, linkedProjectPath: String): Unit = ???

  override def onBulkChangeStart(): Unit = ???

  override def onBulkChangeEnd(): Unit = ???
}

object StackSettingsListener {

  def TOPIC[A >: StackSettingsListener]: Topic[A] =
    _topic.asInstanceOf[Topic[A]]

  private val _topic: Topic[StackSettingsListener] =
    Topic.create("Stack project settings", classOf[StackSettingsListener])
}
